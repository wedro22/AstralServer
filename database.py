# database.py
import sqlite3

def init_db():
    conn = sqlite3.connect('astral.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS CommandList (
                id INTEGER PRIMARY KEY,
                client TEXT,
                data TEXT,
                type TEXT   
                )''')
    c.execute('CREATE INDEX IF NOT EXISTS idx_client ON CommandList (client)')
    c.execute('''CREATE TABLE IF NOT EXISTS Clients (
                client TEXT PRIMARY KEY
                )''')
    conn.commit()
    conn.close()

def get_all_clients():
    conn = sqlite3.connect('astral.db')
    c = conn.cursor()
    c.execute("SELECT client FROM Clients")
    clients = [row[0] for row in c.fetchall()]
    conn.close()
    return clients

def add_client(client_name):
    conn = sqlite3.connect('astral.db')
    c = conn.cursor()
    c.execute("INSERT OR IGNORE INTO Clients (client) VALUES (?)", (client_name,))
    conn.commit()
    conn.close()