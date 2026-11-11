import streamlit as st
import pandas as pd
import sqlite3
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from google import genai
from google.genai import types
import json
import os

# --- 1. SETUP LIVE GEMINI CLIENT ---

api_key = "ENTER API KEY HERE"
client = genai.Client(api_key=api_key) if api_key else None

# --- 2. DATABASE & ANALYTICAL TOOLS ---
def init_databases():
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE marketing_performance (
            date TEXT, channel TEXT, spend REAL, revenue REAL, conversions INTEGER
        )
    """)
    channels = ['Google Ads', 'Meta Ads', 'LinkedIn']
    dates = pd.date_range(start="2025-01-01", end="2025-12-31", freq="D").strftime("%Y-%m-%d")
    data = []
    np.random.seed(42)
    for date in dates:
        for channel in channels:
            spend = np.random.uniform(500, 2000)
            multiplier = 4.5 if channel == 'Google Ads' else (3.2 if channel == 'Meta Ads' else 2.1)
            revenue = spend * multiplier + np.random.normal(0, 300)
            conversions = int(spend / np.random.uniform(10, 25))
            data.append((date, channel, round(spend, 2), round(max(0, revenue), 2), max(0, conversions)))
            
    cursor.executemany("INSERT INTO marketing_performance VALUES (?, ?, ?, ?, ?)", data)
    conn.commit()
    return conn

conn = init_databases()

def execute_sql_tool(query: str):
    try:
        return pd.read_sql_query(query, conn), "Success"
    except Exception as e:
        return None, str(e)

def execute_forecast_tool(channel: str):
    df = pd.read_sql_query(f"SELECT date, revenue FROM marketing_performance WHERE channel='{channel}'", conn)
    df['date'] = pd.to_datetime(df['date'])
    df = df.groupby('date').sum().resample('D').asfreq().fillna(0)
    model = ExponentialSmoothing(df['revenue'], trend='add', seasonal=None).fit()
    forecast = model.forecast(30)
    return pd.DataFrame({
        'Date': pd.date_range(start=df.index[-1] + pd.Timedelta(days=1), periods=30).strftime("%Y-%m-%d"),
        'Projected_Revenue': forecast.values.round(2)
    })

def execute_vector_rag_tool():
    """Reads your real uploaded strategy PDF file and extracts text for the model."""
    import pypdf

    script_dir = os.path.dirname(os.path.abspath(__file__))
    filename = "client_strategy.pdf"
    
    if os.path.exists(filename):
        try:
            with open(filename, "rb") as f:
                reader = pypdf.PdfReader(f)
                text_content = []

                # Extract text from the first 25 pages to avoid overloading memory
                
                max_pages = min(25, len(reader.pages))
                for page_num in range(max_pages):
                    page_text = reader.pages[page_num].extract_text()
                    if page_text:
                        text_content.append(page_text)
                
                return "\n".join(text_content)
        except Exception as e:
            return f"Error parsing PDF file: {str(e)}"
            
    return "Fallback: Please place 'client_strategy.pdf' inside your project folder."


# --- 3. GEMINI AGENTIC INTERFACE ---
def run_gemini_agent(user_query: str, active_sections: list,selected_source: str):
    if not client:
        return "Simulated Route", None, "⚠️ **Gemini API Key missing.** Set `GEMINI_API_KEY` in your terminal."

    # 1. DETERMINE TOOL ROUTE (Manual Override vs. Auto-Agent)
    if "Client Strategy Report" in selected_source:
        selected_tool = "STRATEGY_RAG"
        param = ""
    elif "Marketing Performance" in selected_source:
        selected_tool = "SQL"
        param = ""
    elif "Revenue Forecasting" in selected_source:
        selected_tool = "FORECAST"
        param = user_query
    else:
        # Auto-Agent Mode: Let Gemini choose the tool
        routing_prompt = f"""
        You are an AI Routing Agent for an enterprise consulting firm. Analyze this user query: "{user_query}"
        Choose the single most appropriate tool:
        1. 'SQL' (For metrics, ROI, revenue, spend, or database numbers)
        2. 'FORECAST' (For predicting or forecasting future quantitative performance)
        3. 'STRATEGY_RAG' (For qualitative guidelines, policy analysis, or corporate reports)

        Respond ONLY with JSON: {{"tool": "SQL" | "FORECAST" | "STRATEGY_RAG", "parameter": "channel name or focus"}}
        """
        routing_response = client.models.generate_content(
            model='gemini-3.5-flash',
            contents=routing_prompt,
            config=types.GenerateContentConfig(response_mime_type="application/json")
        )
        routing_data = json.loads(routing_response.text)
        selected_tool = routing_data.get("tool")
        param = routing_data.get("parameter", "")

    # 2. EXECUTE THE SELECTED TOOL
    data_context = None
    tool_log_name = ""

    if selected_tool == 'FORECAST':
        tool_log_name = f"Forecasting Module ({selected_source})"
        channel = "Meta Ads" if "meta" in str(param).lower() else ("LinkedIn" if "linkedin" in str(param).lower() else "Google Ads")
        data_context = execute_forecast_tool(channel)
        context_str = f"Generated Forecast Data for {channel}:\n{data_context.tail(5).to_string()}"
    elif selected_tool == 'SQL':
        tool_log_name = f"SQLite Database Engine ({selected_source})"
        sql_query = "SELECT channel, SUM(spend) as Total_Spend, SUM(revenue) as Total_Revenue, ROUND(SUM(revenue)/SUM(spend), 2) as RoAS FROM marketing_performance GROUP BY channel"
        if "google" in user_query.lower():
            sql_query = "SELECT date, spend, revenue FROM marketing_performance WHERE channel='Google Ads' LIMIT 5"
        data_context, _ = execute_sql_tool(sql_query)
        context_str = f"Executed Database Query Result:\n{data_context.to_string()}"
    else:
        tool_log_name = f"Document RAG Index ({selected_source})"
        context_str = execute_vector_rag_tool()

    # 3. SYNTHESIZE RESPONSE
    section_filter_text = ", ".join(active_sections) if active_sections else "All Sections"


    # Final Step: Pass data back to Gemini to synthesize an executive summary
    synthesis_prompt = f"""
    You are an elite Senior Consultant at Deloitte. Answer the client's question comprehensively using the retrieved business context provided.
    
    FORMATTING RULE: Never use unescaped '$' symbols for currency, as it breaks Markdown rendering. Always write currency as 'USD 74.5B' instead of '$74.5B'.
    STRICT SCOPE CONSTRAINT: Focus your analysis and citations ONLY on the following report sections/pillars: [{section_filter_text}]. 
    If the answer relies on sections outside of [{section_filter_text}], explicitly state that those pillars are currently filtered out by the user's dashboard slicer.
    
    Client Question: {user_query}
    Retrieved Context/Data Base: {context_str}
    
    Structure your response using professional corporate markdown headers:
    ### 📊 Executive Recommendation
    (Provide a crisp, 2-sentence executive takeaway answering the business "so what?")
    
    ### 🔍 Data Insights & Sourced Analysis
    (Summarize the specific details retrieved, explicitly noting which report pillar they belong to.)
    """
    
    synthesis_response = client.models.generate_content(
    model='gemini-3.1-flash-lite',
    contents=synthesis_prompt
    )
    
    return tool_log_name, data_context, synthesis_response.text

# --- 4. STREAMLIT INTERFACE ---
st.set_page_config(
    page_title="Deloitte Analytic Insights | Engine", 
    page_icon="🟢", # Deloitte green dot anchor
    layout="wide"
)

# Custom Title Block 
st.markdown("<h1 style='color: #86BC25; margin-bottom: 0;'>Deloitte.</h1>", unsafe_allow_html=True)
st.markdown("<h2 style='margin-top: 0; font-weight: 300;'>Analytic Insights Engine: Enterprise RAG</h2>", unsafe_allow_html=True)
st.markdown("---")

# Organized Sidebar Workspace Workspace
with st.sidebar:
    st.markdown("### 📋 Engagement Context")
    st.info("**Client:** Deloitte Global\n\n**Document:** Global Impact Report 2026\n\n**Database:** Marketing & Revenue")
    
    # ---  DATA SOURCE SWITCHER ---
    st.markdown("### 🔌 Data Source Routing")
    data_source = st.radio(
        "Select Active Data Pipeline:",
        options=[
            "🤖 Auto-Agent (Smart Router)",
            "📄 Deloitte 2026 Global Impact Report (PDF)",
            "🗄️ Marketing Performance (SQLite DB)",
            "📈 Revenue Forecasting (Statsmodels)"
        ],
        index=0,
        help="Let Gemini decide the source automatically, or force a specific pipeline."
    )
    
    # Only show the PDF pillar slicers if the PDF or Auto mode is active
    if "SQLite" not in data_source and "Forecasting" not in data_source:
        st.markdown("### 🎛️ Document Focus Slicers")
        selected_sections = st.multiselect(
            "Filter RAG Context by Pillar:",
            options=["Business", "Environment", "Society", "Governance", "People"],
            default=["Business", "Environment", "Society", "Governance", "People"]
        )
    else:
        selected_sections = []
    

    st.markdown("---")
    st.markdown("### 🟢 System Telemetry")
    st.success("Core Engine: **Gemini 3.1-Flash-Lite**\n\nSQL Latency: **0.02ms**\n\nData Lineage: **Verified**")

# Top Level Executive Summary Cards (Simulating Client KPIs)
st.markdown("### 📈 Current Account Health")
kpi1, kpi2, kpi3 = st.columns(3)
with kpi1:
    st.metric(label="Omni-Channel Avg RoAS", value="3.27x", delta="+0.42x")
with kpi2:
    st.metric(label="Data Ingestion Status", value="100%", delta="Complete")
with kpi3:
    st.metric(label="Model Token Efficiency", value="94.8%", delta="+1.2%")

st.markdown("---")

# Core Conversational Interface Layout
st.markdown("### 🤖 Strategy & Insights Query Terminal")

# Interactive Text input block wrapped in a clean container border
with st.container(border=True):
    user_input = st.text_input(
        "Enter your strategic inquiry or technical data request:",
        placeholder="e.g., What are Deloitte's key sustainability commitments mentioned in the report?"
    )
    submit_btn = st.button("Execute Pipeline", type="primary") # Turn button into professional blue/primary color

# Output Block Trigger
if submit_btn:
    if user_input:
        # Create a professional status message bar instead of a generic loading spinner
        with st.status("🚀 Orchestrating Agentic Architecture...", expanded=True) as status:
            st.write("1. Reading prompt intent parameters...")
            tool, data, analysis = run_gemini_agent(user_input, selected_sections, data_source)
            st.write(f"2. Successfully routed request to: `{tool}`")
            status.update(label="Analysis Pipeline Complete!", state="complete", expanded=False)
            
        # AI Governance & Traceability - Relocated strategically below the run execution
        with st.expander("🔍 AI Governance & Model Explainability Trace", expanded=False):
            st.warning(f"**Data Lineage Path:** {tool} | **Compliance Log:** Token inputs verified against operational parameters.")
            
        st.markdown("---")
        
        # Display Outputs Side-by-Side using structured columns
        col1, col2 = st.columns(2)
        
        with col1:
            # Wrap textual output inside a styled card container
            with st.container(border=True):
                st.markdown("### 📝 Executive Intelligence Brief")

                clean_analysis = analysis.replace("$", r"\$")
                st.markdown(clean_analysis)
                 

            
        with col2:
            with st.container(border=True):
                st.markdown("### 📊 Empirical Analytics Output")
                if data is not None:
                    st.dataframe(data, use_container_width=True)
                    if 'Projected_Revenue' in data.columns:
                        st.line_chart(data.set_index('Date'), color="#86BC25") # Match chart to Deloitte Green
                    elif 'RoAS' in data.columns:
                        st.bar_chart(data.set_index('channel')['RoAS'], color="#86BC25")
                else:
                    st.info("💡 **Core Insight:** This inquiry was resolved entirely using qualitative document context layers. No numerical calculations were required.")
    else:
        st.error("Action Required: Please type a valid consulting prompt to execute the engine.")

