import sys
import socket
import threading
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QTextEdit, QHBoxLayout
from PyQt5.QtCore import Qt

class TCPServer:
    def __init__(self, host='0.0.0.0', port=4040):
        self.host = host
        self.port = port
        self.server_socket = None
        self.connected_clients = []
        self.client_nicknames = {}  # Stores client nicknames

    def start_server(self):
        """Start the server and listen for incoming connections."""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(5)  # Max 5 clients

        self.log_message(f"Server started on {self.host}:{self.port}")

        while True:
            client_socket, client_address = self.server_socket.accept()
            self.log_message(f"New connection from {client_address}")
            self.connected_clients.append(client_socket)

            # Start a new thread to handle client communication
            threading.Thread(target=self.handle_client, args=(client_socket, client_address)).start()

    def handle_client(self, client_socket, client_address):
        """Handle communication with a client."""
        nickname = f"Client-{client_address}"
        self.client_nicknames[client_socket] = nickname

        try:
            while True:
                data = client_socket.recv(1024)
                if not data:
                    break

                message = data.decode().strip()

                self.log_message(f"Received message from {nickname}: {message}")

                # Handle the received message
                if message.startswith("Nickname:"):
                    self.handle_nickname(client_socket, message)
                elif message.startswith("Question:"):
                    self.handle_question(client_socket, message)
                else:
                    self.handle_chat(client_socket, message)

        except Exception as e:
            self.log_message(f"Error while handling client {client_address}: {e}")

        finally:
            # Client disconnects
            self.log_message(f"{nickname} disconnected")
            self.connected_clients.remove(client_socket)
            del self.client_nicknames[client_socket]
            client_socket.close()

    def handle_nickname(self, client_socket, message):
        """Update the client's nickname."""
        new_nickname = message[9:].strip()
        self.client_nicknames[client_socket] = new_nickname
        self.send_message_to_all(f'{new_nickname} has connected.')

    def handle_question(self, client_socket, message):
        """Forward a question to all clients."""
        question = message[9:].strip()
        nickname = self.client_nicknames[client_socket]
        self.send_message_to_all(f'{nickname} asked: {question}')

    def handle_chat(self, client_socket, message):
        """Forward chat messages to all clients."""
        nickname = self.client_nicknames[client_socket]
        self.send_message_to_all(f"{nickname}: {message}")

    def send_message_to_all(self, message):
        """Send a message to all connected clients."""
        for client_socket in self.connected_clients:
            try:
                client_socket.sendall(message.encode())  # Send message using sendall
            except Exception as e:
                self.log_message(f"Error sending message to client: {e}")

    def start_session(self):
        """Start the session and notify all connected clients with 'Session started'."""
        session_message = "Session started"
        self.log_message(session_message)
        self.send_message_to_all(session_message)  # Send message to all clients

    def stop_server(self):
        """Stop the server and close all client connections."""
        for client_socket in self.connected_clients:
            client_socket.close()
        self.server_socket.close()
        self.log_message("Server stopped.")

    def log_message(self, message):
        """Log the message to the UI console."""
        self.ui_console.append(message)

    def set_ui_console(self, ui_console):
        """Set the QTextEdit widget to log messages."""
        self.ui_console = ui_console

class ServerUI(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("TCP Server with PyQt5")
        self.setGeometry(100, 100, 600, 400)

        self.server = TCPServer()

        self.init_ui()

    def init_ui(self):
        # Layouts
        layout = QVBoxLayout()
        button_layout = QHBoxLayout()

        # Console for logging
        self.ui_console = QTextEdit(self)
        self.ui_console.setReadOnly(True)
        layout.addWidget(self.ui_console)

        # Start Server button
        self.start_server_button = QPushButton("Start Server", self)
        self.start_server_button.clicked.connect(self.start_server)
        button_layout.addWidget(self.start_server_button)

        # Start Session button
        self.start_session_button = QPushButton("Start Session", self)
        self.start_session_button.clicked.connect(self.start_session)
        button_layout.addWidget(self.start_session_button)

        layout.addLayout(button_layout)

        self.setLayout(layout)

        # Set the console for logging messages
        self.server.set_ui_console(self.ui_console)

    def start_server(self):
        """Start the server."""
        threading.Thread(target=self.server.start_server, daemon=True).start()

    def start_session(self):
        """Start the session."""
        self.server.start_session()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ServerUI()
    window.show()
    sys.exit(app.exec_())
