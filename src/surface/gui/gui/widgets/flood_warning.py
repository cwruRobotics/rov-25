from gui.event_nodes.subscriber import GUIEventSubscriber
from PyQt6.QtCore import pyqtSignal, pyqtSlot
from PyQt6.QtGui import QFont
from PyQt6.QtWidgets import QLabel, QVBoxLayout, QWidget

from rov_msgs.msg import Flooding


class FloodWarning(QWidget):

    signal = pyqtSignal(Flooding)

    def __init__(self) -> None:
        super().__init__()
        # Boilerplate PyQt Setup to link to ROS through a signal/subscriber
        self.signal.connect(self.refresh)
        self.subscription = GUIEventSubscriber(Flooding, 'flooding', self.signal)
        # Create a latch variable
        self.warning_msg_latch = False
        # Create basic 2 vertical stacked boxes layout
        self.flood_layour = QVBoxLayout()
        # Create the label that tells us what this is
        self.label = QLabel('Flooding Indicator')
        font = QFont("Arial", 14)
        self.label.setFont(font)
        self.flood_layour.addWidget(self.label)

        self.indicator = QLabel('No Water present')
        self.indicator.setFont(font)
        self.flood_layour.addWidget(self.indicator)
        self.setLayout(self.flood_layour)

    @pyqtSlot(Flooding)
    def refresh(self, msg: Flooding) -> None:
        if msg.flooding:
            self.indicator.setText('FLOODING')
            self.subscription.get_logger().error("Robot is actively flooding, do something!")
            self.warning_msg_latch = True
        else:
            self.indicator.setText('No Water present')
            if self.warning_msg_latch:
                self.subscription.get_logger().warning("Robot flooding has reset itself.")
                self.warning_msg_latch = False