from gui.operator_app import OperatorApp
from pytestqt.qtbot import QtBot


def test_app_instantiation(qtbot: QtBot) -> None:
    """Unit test for OperatorApp instantiation."""
    app = OperatorApp()
    app.show()
    qtbot.addWidget(app)
