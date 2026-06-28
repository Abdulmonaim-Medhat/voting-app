from flask import Flask, render_template, Response
import psycopg2
import time
import json
import os

app = Flask(__name__)

POSTGRES_HOST = os.environ.get('POSTGRES_HOST', 'postgres')
POSTGRES_DB   = os.environ.get('POSTGRES_DB', 'vote')
POSTGRES_USER = os.environ.get('POSTGRES_USER', 'kareem')
POSTGRES_PASS = os.environ.get('POSTGRES_PASSWORD', 'secret')

def get_db():
    while True:
        try:
            return psycopg2.connect(
                host=POSTGRES_HOST,
                database=POSTGRES_DB,
                user=POSTGRES_USER,
                password=POSTGRES_PASS
            )
        except psycopg2.OperationalError:
            time.sleep(1)

def get_results():
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT vote, COUNT(*) FROM votes GROUP BY vote")
        rows = cur.fetchall()
    conn.close()
    results     = {row[0]: row[1] for row in rows}
    total       = sum(results.values())
    alahly      = results.get('alahly', 0)
    elzamalek   = results.get('elzamalek', 0)
    return {
        'alahly':        alahly,
        'elzamalek':     elzamalek,
        'alahly_pct':    round(alahly    / total * 100) if total else 0,
        'elzamalek_pct': round(elzamalek / total * 100) if total else 0,
        'total':         total
    }

@app.route('/')
def index():
    return render_template('result.html')

@app.route('/stream')
def stream():
    def event_stream():
        last = None
        while True:
            data = get_results()
            if data != last:
                yield f"data: {json.dumps(data)}\n\n"
                last = data
            time.sleep(2)
    return Response(event_stream(), mimetype='text/event-stream')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True, threaded=True)
