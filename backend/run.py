import os
from dotenv import load_dotenv

load_dotenv()

def create_app(config_name=None):
    from app import create_app as create_flask_app
    
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'production')
    
    return create_flask_app(config_name)

if __name__ == '__main__':
    app = create_app()
    
    env = os.getenv('FLASK_ENV', 'development')
    if env == 'development':
        app.run(debug=True, host='0.0.0.0', port=5000)
    else:
        print("Para producción usa gunicorn:")
        print("gunicorn -w 4 -b 0.0.0.0:5000 'run:create_app()'")
