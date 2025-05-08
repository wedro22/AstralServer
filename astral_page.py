# astral_page.py
from bottle import template

def setup_astral_routes(app):
    @app.route('/astral')
    def astral_page():
        clients = ["client1", "client2", "client3"]  # Заглушка, нужно заменить на вызов функции

        return template('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Astral Control</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                #client-selector { margin-bottom: 20px; }
                #output-container, #input-container { 
                    width: 100%;
                    margin-bottom: 20px;
                }
                #output-display {
                    width: 100%;
                    height: 300px;
                    border: 1px solid #ccc;
                    padding: 10px;
                    overflow-y: scroll;
                    background-color: #f9f9f9;
                }
                #input-field {
                    width: 100%;
                    height: 150px;
                    border: 1px solid #ccc;
                    padding: 10px;
                }
                .half-page {
                    width: 100%;
                    box-sizing: border-box;
                }
            </style>
        </head>
        <body>
            <h1>Astral Control Panel</h1>

            <div id="client-selector">
                <input list="clients" id="client-input" placeholder="Select or add client">
                <datalist id="clients">
                    % for client in clients:
                        <option value="{{client}}">
                    % end
                </datalist>
                <button onclick="selectClient()">Select</button>
            </div>

            <div class="half-page" id="output-container">
                <h3>Output:</h3>
                <div id="output-display" contenteditable="false">
                    Select a client to view data
                </div>
            </div>

            <div class="half-page" id="input-container">
                <h3>Input:</h3>
                <textarea id="input-field" 
                          placeholder="Type your command here... (Shift+Enter for new line, Enter to send)"
                          onkeydown="handleKeyDown(event)"></textarea>
            </div>

            <script>
                let currentClient = null;

                async function selectClient() {
                    const input = document.getElementById('client-input');
                    currentClient = input.value.trim();

                    if (currentClient) {
                        // Добавляем нового клиента (если его нет)
                        try {
                            const response = await fetch('/add_client', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/x-www-form-urlencoded',
                                },
                                body: `client_name=${encodeURIComponent(currentClient)}`
                            });

                            if (!response.ok) throw new Error('Failed to add client');

                            // Обновляем datalist
                            updateClientList();

                            // Выводим информацию о клиенте
                            document.getElementById('output-display').innerText = 
                                `Selected client: ${currentClient}\nReady for commands`;

                        } catch (error) {
                            console.error('Error:', error);
                            alert('Error selecting client');
                        }
                    }
                }

                async function updateClientList() {
                    const response = await fetch('/astral');
                    const html = await response.text();
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const newDatalist = doc.getElementById('clients').innerHTML;
                    document.getElementById('clients').innerHTML = newDatalist;
                }

                function handleKeyDown(event) {
                    if (event.key === 'Enter' && !event.shiftKey) {
                        event.preventDefault();
                        sendCommand();
                    }
                }

                function sendCommand() {
                    const inputField = document.getElementById('input-field');
                    const command = inputField.value;

                    if (command && currentClient) {
                        const output = document.getElementById('output-display');
                        output.innerText += `\n[${currentClient}] > ${command}`;
                        output.scrollTop = output.scrollHeight;
                        inputField.value = '';
                    } else if (!currentClient) {
                        alert('Please select a client first');
                    }
                }
            </script>
        </body>
        </html>
        ''', clients=clients)