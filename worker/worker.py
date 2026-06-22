import redis
import psycopg2
import time

def get_redis():
    while True:
        try:
            r = redis.Redis(host='redis', port=6379)
            r.ping()
            print("Connected to Redis")
            return r
        except redis.exceptions.ConnectionError:
            print("Waiting for Redis...")
            time.sleep(1)

def get_postgres():
    while True:
        try:
            conn = psycopg2.connect(
                host='postgres',
                database='vote',
                user='kareem',
                password='secret'
            )
            print("Connected to PostgreSQL")
            return conn
        except psycopg2.OperationalError:
            print("Waiting for PostgreSQL...")
            time.sleep(1)

def init_db(conn):
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS votes (
                voter_id VARCHAR(255) PRIMARY KEY,
                vote     VARCHAR(255) NOT NULL,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        """)
    conn.commit()
    print("DB initialized")

def process_vote(conn, voter_id, vote):
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO votes (voter_id, vote)
            VALUES (%s, %s)
            ON CONFLICT (voter_id)
            DO UPDATE SET vote = EXCLUDED.vote
        """, (voter_id, vote))
    conn.commit()
    print(f"Recorded vote: {voter_id} -> {vote}")

def main():
    r = get_redis()
    conn = get_postgres()
    init_db(conn)

    print("Worker ready, waiting for votes...")
    while True:
        try:
            _, data = r.blpop('votes')
            voter_id, vote = data.decode().split(':')
            process_vote(conn, voter_id, vote)
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)

if __name__ == '__main__':
    main()
