import os
import smtplib
import pymysql
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')  # Backend sin GUI
import io
from flask import Flask, render_template, jsonify, request
from functools import wraps
import base64

app = Flask(__name__)

# Credenciales de acceso
ADMIN_PASSWORD = os.getenv('ADMIN_PASSWORD', 'admin123')

DB_HOST = os.getenv('DB_HOST', 'db')
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')
DB_NAME = os.getenv('DB_NAME', 'usuarios')

COMUNAS = [f'Comuna {i}' for i in range(1, 11)]
CARRERAS = ['Medicina', 'Ingeniería', 'Abogacía', 'Licenciatura']

def require_password(f):
    """Decorador para validar contraseña"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        password = request.args.get('password') or request.form.get('password')
        if password != ADMIN_PASSWORD:
            return jsonify({'error': 'Acceso denegado'}), 403
        return f(*args, **kwargs)
    return decorated_function

def get_db_connection():
    """Conectar a la base de datos"""
    try:
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4'
        )
        return connection
    except Exception as e:
        print(f"Error de conexión: {e}")
        return None

def get_statistics():
    """Obtener estadísticas de registros"""
    connection = get_db_connection()
    if not connection:
        return None
    
    try:
        cursor = connection.cursor(pymysql.cursors.DictCursor)
        
        # Total de registros
        cursor.execute("SELECT COUNT(*) as total FROM registros")
        total = cursor.fetchone()['total']
        
        # Registros por comuna
        cursor.execute("""
            SELECT comuna, COUNT(*) as cantidad 
            FROM registros 
            GROUP BY comuna 
            ORDER BY cantidad DESC
        """)
        registros_por_comuna = cursor.fetchall()
        
        # Registros por carrera
        cursor.execute("""
            SELECT carrera, COUNT(*) as cantidad 
            FROM registros 
            GROUP BY carrera 
            ORDER BY cantidad DESC
        """)
        registros_por_carrera = cursor.fetchall()
        
        # Registros por comuna y carrera
        cursor.execute("""
            SELECT comuna, carrera, COUNT(*) as cantidad 
            FROM registros 
            GROUP BY comuna, carrera
            ORDER BY comuna, carrera
        """)
        registros_cruzados = cursor.fetchall()
        
        connection.close()
        
        return {
            'total': total,
            'por_comuna': registros_por_comuna,
            'por_carrera': registros_por_carrera,
            'cruzados': registros_cruzados
        }
    except Exception as e:
        print(f"Error al obtener estadísticas: {e}")
        connection.close()
        return None

def create_chart(title, labels, values, chart_type='bar'):
    """Crear gráfica en memoria"""
    plt.figure(figsize=(10, 6))
    
    if chart_type == 'bar':
        plt.bar(labels, values, color='#667eea')
    elif chart_type == 'pie':
        colors = plt.cm.Set3(range(len(labels)))
        plt.pie(values, labels=labels, autopct='%1.1f%%', colors=colors)
    
    plt.title(title, fontsize=16, fontweight='bold')
    plt.xlabel('Categoría', fontsize=12)
    plt.ylabel('Cantidad', fontsize=12)
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    
    # Convertir a imagen
    img = io.BytesIO()
    plt.savefig(img, format='png', dpi=100)
    img.seek(0)
    plt.close()
    
    return base64.b64encode(img.getvalue()).decode()

@app.route('/')
def dashboard():
    """Panel de control"""
    stats = get_statistics()
    if not stats:
        return 'Error al conectar con la base de datos', 500
    
    # Crear gráficas
    comunas = [c['comuna'] for c in stats['por_comuna']]
    valores_comunas = [c['cantidad'] for c in stats['por_comuna']]
    chart_comunas = create_chart('Registros por Comuna', comunas, valores_comunas)
    
    carreras = [c['carrera'] for c in stats['por_carrera']]
    valores_carreras = [c['cantidad'] for c in stats['por_carrera']]
    chart_carreras = create_chart('Registros por Carrera', carreras, valores_carreras, 'pie')
    
    return render_template('dashboard.html', 
                          stats=stats,
                          chart_comunas=chart_comunas,
                          chart_carreras=chart_carreras,
                          total=stats['total'])

@app.route('/stats')
def stats_page():
    """Panel de control (ruta alternativa)"""
    return dashboard()

@app.route('/api/statistics')
def api_statistics():
    """API para obtener estadísticas en JSON"""
    stats = get_statistics()
    if not stats:
        return jsonify({'error': 'Error al obtener estadísticas'}), 500
    return jsonify(stats)

@app.route('/api/send-report', methods=['POST'])
@require_password
def send_report():
    """Enviar reporte por correo"""
    stats = get_statistics()
    if not stats:
        return jsonify({'error': 'Error al obtener estadísticas'}), 500
    
    # Obtener email destinatario del parámetro
    email_destino = request.args.get('email') or 'cccabarcal@eafit.edu.co'
    
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"Reporte de Estadísticas - {datetime.now().strftime('%d/%m/%Y %H:%M')}"
        msg['From'] = os.getenv('EMAIL_FROM', 'cccabarcal@eafit.edu.co')
        msg['To'] = email_destino
        
        html_content = "<html><body style='font-family: Arial, sans-serif; color: #f5f5f5; background: #1a1a1a;'>"
        html_content += "<h2 style='color: #a855f7;'>Reporte de Estadísticas de Registros</h2>"
        html_content += f"<p><strong>Fecha:</strong> {datetime.now().strftime('%d de %B de %Y a las %H:%M')}</p>"
        html_content += "<h3 style='color: #a855f7;'>Resumen General</h3>"
        html_content += f"<p><strong>Total de Registros:</strong> {stats['total']}</p>"
        
        html_content += "<h3 style='color: #a855f7;'>Registros por Comuna</h3>"
        html_content += "<table border='1' cellpadding='10' cellspacing='0' style='border-collapse: collapse; color: #d8b4fe;'>"
        html_content += "<tr style='background-color: #4a148c;'>"
        html_content += "<th style='color: #a855f7;'>Comuna</th><th style='color: #a855f7;'>Cantidad</th></tr>"
        for comuna in stats['por_comuna']:
            html_content += f"<tr><td>{comuna['comuna']}</td><td>{comuna['cantidad']}</td></tr>"
        html_content += "</table>"
        
        html_content += "<h3 style='color: #a855f7;'>Registros por Carrera</h3>"
        html_content += "<table border='1' cellpadding='10' cellspacing='0' style='border-collapse: collapse; color: #d8b4fe; margin-top: 20px;'>"
        html_content += "<tr style='background-color: #4a148c;'>"
        html_content += "<th style='color: #a855f7;'>Carrera</th><th style='color: #a855f7;'>Cantidad</th></tr>"
        for carrera in stats['por_carrera']:
            html_content += f"<tr><td>{carrera['carrera']}</td><td>{carrera['cantidad']}</td></tr>"
        html_content += "</table>"
        
        html_content += "<h3 style='color: #a855f7;'>Análisis Cruzado (Comuna x Carrera)</h3>"
        html_content += "<table border='1' cellpadding='10' cellspacing='0' style='border-collapse: collapse; color: #d8b4fe; margin-top: 20px;'>"
        html_content += "<tr style='background-color: #4a148c;'>"
        html_content += "<th style='color: #a855f7;'>Comuna</th><th style='color: #a855f7;'>Carrera</th><th style='color: #a855f7;'>Cantidad</th></tr>"
        for cruzado in stats['cruzados']:
            html_content += f"<tr><td>{cruzado['comuna']}</td><td>{cruzado['carrera']}</td><td>{cruzado['cantidad']}</td></tr>"
        html_content += "</table>"
        
        html_content += "<p style='margin-top: 30px; color: #7c3aed; font-size: 12px;'>Este es un reporte automático generado por el sistema.</p>"
        html_content += "</body></html>"
        
        msg.attach(MIMEText(html_content, 'html'))
        
        smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
        smtp_port = int(os.getenv('SMTP_PORT', 587))
        smtp_user = os.getenv('SMTP_USER', '')
        smtp_password = os.getenv('SMTP_PASSWORD', '')
        
        if not smtp_user or not smtp_password:
            return jsonify({
                'success': True, 
                'message': 'Reporte generado (envío de correo no configurado)'
            }), 200
        
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_password)
            server.send_message(msg)
        
        return jsonify({
            'success': True,
            'message': f'Reporte enviado exitosamente a {email_destino}'
        }), 200
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/health')
def health():
    """Endpoint de salud"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
