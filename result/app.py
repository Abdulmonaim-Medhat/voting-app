from flask import Flask, render_template, Response
import psycopg2
import time
import json

app = Flask(__name__)

def get_db():
    while True:
        try:
            return psycopg2.connect(
                host='postgres',
                database='vote',
                user='kareem',
                password='secret'
            )
        except psycopg2.OperationalError:
            time.sleep(1)

def get_results():
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT vote, COUNT(*) FROM votes GROUP BY vote")
        rows = cur.fetchall()
    conn.close()
    results = {row[0]: row[1] for row in rows}
    total = sum(results.values())
    cats  = results.get('cats', 0)
    dogs  = results.get('dogs', 0)
    return {
        'cats': cats,
        'dogs': dogs,
        'cats_pct': round(cats / total * 100) if total else 0,
        'dogs_pct': round(dogs / total * 100) if total else 0,
        'total': total
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
