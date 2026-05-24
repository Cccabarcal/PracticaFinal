from flask import Flask, render_template, request, jsonify
from datetime import datetime
import pymysql
import os

app = Flask(__name__)

def get_db_connection():
    """Crear conexión a la base de datos"""
    conn = pymysql.connect(
        host=os.getenv('DB_HOST', 'db'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'password'),
        database=os.getenv('DB_NAME', 'usuarios'),
        charset='utf8mb4'
    )
    return conn

# Determinar idioma basado en la variable de entorno
LANGUAGE = os.getenv('LANGUAGE', 'es')

COMUNAS = {
    'es': ['Comuna 1', 'Comuna 2', 'Comuna 3', 'Comuna 4', 'Comuna 5', 
           'Comuna 6', 'Comuna 7', 'Comuna 8', 'Comuna 9', 'Comuna 10'],
    'en': ['Commune 1', 'Commune 2', 'Commune 3', 'Commune 4', 'Commune 5',
           'Commune 6', 'Commune 7', 'Commune 8', 'Commune 9', 'Commune 10']
}

CARRERAS = {
    'es': ['Medicina', 'Ingeniería', 'Abogacía', 'Licenciatura'],
    'en': ['Medicine', 'Engineering', 'Law', 'Teaching']
}

@app.route('/')
def index():
    if LANGUAGE == 'en':
        return render_template('index_en.html', comunas=COMUNAS['en'], carreras=CARRERAS['en'])
    else:
        return render_template('index_es.html', comunas=COMUNAS['es'], carreras=CARRERAS['es'])

@app.route('/es')
def es():
    return render_template('index_es.html', comunas=COMUNAS['es'], carreras=CARRERAS['es'])

@app.route('/en')
def en():
    return render_template('index_en.html', comunas=COMUNAS['en'], carreras=CARRERAS['en'])

@app.route('/register', methods=['POST'])
def register():
    conn = None
    try:
        data = request.get_json()
        
        # Validar datos
        if not all(k in data for k in ['nombre', 'comuna', 'carrera']):
            return jsonify({'success': False, 'message': 'Datos incompletos'}), 400
        
        nombre = data['nombre'].strip()
        comuna = data['comuna']
        carrera = data['carrera']
        fecha = datetime.now()
        
        if not nombre or len(nombre) < 2:
            return jsonify({'success': False, 'message': 'Nombre inválido'}), 400
        
        # Insertar en base de datos
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO registros (nombre, comuna, carrera, fecha) VALUES (%s, %s, %s, %s)",
            (nombre, comuna, carrera, fecha)
        )
        conn.commit()
        cursor.close()
        
        msg = 'Registro exitoso' if LANGUAGE == 'es' else 'Registration successful'
        return jsonify({'success': True, 'message': msg}), 201
    
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/stats')
def stats():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) as total FROM registros")
        result = cursor.fetchone()
        total = result[0] if result else 0
        cursor.close()
        
        return jsonify({'total_registros': total}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
