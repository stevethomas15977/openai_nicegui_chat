from fastapi import FastAPI

from nicegui import app, ui

from os import environ
from dotenv import load_dotenv

from langchain_openai import ChatOpenAI

load_dotenv()
OPENAI_API_KEY = environ.get('OPENAI_API_KEY', 'not-set')

def init(fastapi_app: FastAPI) -> None:
    @ui.page('/')
    def show():
        llm = ChatOpenAI(model_name='gpt-4o-mini', streaming=True, openai_api_key=OPENAI_API_KEY)

        async def send() -> None:
            question = text.value
            text.value = ''

            with message_container:
                ui.chat_message(text=question, sent=True)
                response_message = ui.chat_message(sent=False).props('bg-color=blue-2')
                spinner = ui.spinner(type='dots')

            prompt = f"You are a helpful assistant. Please respond with your answer formatted as Markdown. Please answer the following quesiton.\n\n{question}\n\n"
            response = ''
            async for chunk in llm.astream(prompt):
                response += chunk.content
                response_message.clear()
                with response_message:
                    ui.markdown(response)
                ui.run_javascript('window.scrollTo(0, document.body.scrollHeight)')
            message_container.remove(spinner)

        ui.add_css(r'a:link, a:visited {color: inherit !important; text-decoration: none; font-weight: 500}')

        # the queries below are used to expand the contend down to the footer (content can then use flex-grow to expand)
        ui.query('.q-page').classes('flex')
        ui.query('.nicegui-content').classes('w-full')

        with ui.tabs().classes('w-full') as tabs:
            chat_tab = ui.tab('Chat')
        with ui.tab_panels(tabs, value=chat_tab).classes('w-full max-w-2xl mx-auto flex-grow items-stretch'):
            message_container = ui.tab_panel(chat_tab).classes('items-stretch')

        with ui.footer().classes('bg-white'), ui.column().classes('w-full max-w-3xl mx-auto my-6'):
            with ui.row().classes('w-full no-wrap items-center'):
                placeholder = 'message' if OPENAI_API_KEY != 'not-set' else \
                    'Please provide your OPENAI key in the Python script first!'
                text = ui.input(placeholder=placeholder).props('rounded outlined input-class=mx-3') \
                    .classes('w-full self-center').on('keydown.enter', send)

    ui.run_with(
        fastapi_app,
        storage_secret='pick your private secret here',  # NOTE setting a secret is optional but allows for persistent storage per user
    )