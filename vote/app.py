from flask import Flask, render_template, request, make_response
import redis
import uuid

app = Flask(__name__)
r = redis.Redis(host='redis', port=6379)

@app.route('/', methods=['GET', 'POST'])
def index():
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(uuid.uuid4().int)[2:10]

    vote = None
    if request.method == 'POST':
        vote = request.form.get('vote')
        r.rpush('votes', f"{voter_id}:{vote}")

    resp = make_response(render_template('index.html', vote=vote))
    resp.set_cookie('voter_id', voter_id)
    return resp

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
