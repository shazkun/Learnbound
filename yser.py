import sys
import socket
import threading
import base64
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel,
    QLineEdit, QPushButton, QTextEdit, QMessageBox, QFileDialog
)


class ClientApp(QWidget):
    def __init__(self):
        super().__init__()
        self.init_ui()
        self.socket = None
        self.receiver_thread = None
        self.running = False

    def init_ui(self):
        self.setWindowTitle("Socket Client")

        layout = QVBoxLayout()

        self.ip_input = QLineEdit()
        self.ip_input.setPlaceholderText("Server IP")
        layout.addWidget(QLabel("IP Address:"))
        layout.addWidget(self.ip_input)

        self.port_input = QLineEdit()
        self.port_input.setPlaceholderText("Port")
        layout.addWidget(QLabel("Port:"))
        layout.addWidget(self.port_input)

        self.name_input = QLineEdit()
        self.name_input.setPlaceholderText("Username")
        layout.addWidget(QLabel("Username:"))
        layout.addWidget(self.name_input)

        self.connect_button = QPushButton("Connect & Join")
        self.connect_button.clicked.connect(self.connect_and_join)
        layout.addWidget(self.connect_button)

        self.message_box = QTextEdit()
        self.message_box.setReadOnly(True)
        layout.addWidget(QLabel("Messages:"))
        layout.addWidget(self.message_box)

        self.message_input = QLineEdit()
        self.message_input.setPlaceholderText("Type a message")
        layout.addWidget(self.message_input)

        self.send_button = QPushButton("Send Message")
        self.send_button.clicked.connect(self.send_message)
        layout.addWidget(self.send_button)

        # New button for sending images
        self.image_button = QPushButton("Send Image")
        self.image_button.clicked.connect(self.send_image)
        layout.addWidget(self.image_button)

        self.setLayout(layout)

    def connect_and_join(self):
        host = self.ip_input.text().strip()
        try:
            port = int(self.port_input.text().strip())
        except ValueError:
            QMessageBox.critical(self, "Error", "Port must be a number.")
            return
        username = self.name_input.text().strip()

        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((host, port))

            join_message = f"Nickname:{username}\n"
            self.socket.sendall(join_message.encode())

            self.running = True
            self.receiver_thread = threading.Thread(
                target=self.receive_messages)
            self.receiver_thread.daemon = True
            self.receiver_thread.start()

            QMessageBox.information(
                self, "Connected", "Successfully connected and joined.")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to connect:\n{e}")

    def receive_messages(self):
        while self.running:
            try:
                data = self.socket.recv(1024)
                if data:
                    message = data.decode().strip()
                    self.message_box.append(f"[Server] {message}")
                else:
                    break
            except Exception as e:
                self.message_box.append(f"[Error] {e}")
                break

    def send_message(self):
        if self.socket:
            try:
                message = self.message_input.text().strip()
                if message:
                    self.socket.sendall(f"{message}\n".encode())
                    self.message_box.append(f"[You] {message}")
                    self.message_input.clear()
            except Exception as e:
                self.message_box.append(f"[Send Failed] {e}")

    def send_image(self):
        if not self.socket:
            QMessageBox.critical(self, "Error", "Not connected to server.")
            return

        # Open file dialog to select an image
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Select Image", "", "Images (*.png *.jpg *.jpeg *.bmp *.gif)"
        )
        if not file_path:
            return

        try:
            # Read and encode the image to base64
            with open(file_path, "rb") as image_file:
                image_data = image_file.read()
                base64_image = base64.b64encode(image_data).decode('utf-8')

            # Send the base64-encoded image with 'Image:' prefix
            image_message = f"{base64_image}\n"
            self.socket.sendall(image_message.encode())
            self.message_box.append(
                f"[You] Sent image (length: {len(base64_image)})")
        except Exception as e:
            self.message_box.append(f"[Image Send Failed] {e}")

    def closeEvent(self, event):
        self.running = False
        try:
            if self.socket:
                self.socket.close()
        except:
            pass
        event.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    client = ClientApp()
    client.show()
    sys.exit(app.exec_())
