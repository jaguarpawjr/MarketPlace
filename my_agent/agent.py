from google.adk.agents.llm_agent import Agent

root_agent = Agent(
    model='gemini-2.5-pro',
    name='root_agent',
    description='An agricultural expert in crop disease detection and prevention, assisting with user questions.',
    instruction='Answer user questions to the best of your knowledge',
)
