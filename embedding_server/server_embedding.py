from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer

app = Flask(__name__)
model = SentenceTransformer('all-MiniLM-L6-v2')  # Modelo leve, rápido e eficaz

@app.route('/embed', methods=['POST'])
def embed():
    print("Recebido raw data:", request.data)  # Dados brutos recebidos (bytes)
    data = request.json
    print("JSON decodificado:", data)
    
    texts = data.get('texts', []) if data else None
    if not texts:
        return jsonify({'error': 'No texts provided'}), 400

    embeddings = model.encode(texts).tolist()
    return jsonify({'embeddings': embeddings})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
