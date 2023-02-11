import psycopg2

class MyDataBase():
    def __init__(self, datacon) -> None:
        self.conn = psycopg2.connect(datacon)
        self.cur = self.conn.cursor()

    def query(self, query):
        self.cur.execute(query)

    def close(self):
        self.cur.close()
        self.conn.close()