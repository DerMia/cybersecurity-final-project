# Debian Evidence Collection Scripts

Esta carpeta contiene los scripts y archivos generados durante la fase de análisis forense del proyecto final de ciberseguridad.

## 📌 Objetivo

Automatizar la recolección de evidencias en un sistema Debian comprometido para facilitar:

- Análisis forense inicial
- Identificación de configuraciones inseguras
- Verificación de integridad
- Documentación técnica del estado del sistema

---

## 📂 Contenido

### 🧪 recolectar_evidencias.sh
Script principal encargado de recopilar información relevante del sistema.

Entre otros, obtiene datos sobre:

- Usuarios del sistema
- Procesos activos
- Servicios en ejecución
- Configuración SSH
- Estado de MariaDB
- Permisos en WordPress
- Tareas programadas (cron)
- Binarios SUID
- Logs relevantes

---

### 📄 evidencia_debian_YYYY-MM-DD.txt
Archivo generado automáticamente por el script que contiene:

- Información detallada del sistema
- Resultados de comandos de análisis
- Evidencias recopiladas para revisión manual

---

### 🔐 hashes_debian_YYYY-MM-DD.txt
Archivo con los hashes de integridad generados durante el análisis.

Su objetivo es:

- Verificar que los archivos no han sido modificados posteriormente
- Mantener trazabilidad de la evidencia
- Garantizar integridad forense

---

## ▶️ Cómo ejecutar el script

Desde la máquina Debian:

```bash
chmod +x recolectar_evidencias.sh
sudo ./recolectar_evidencias.sh
