# Cybersecurity Final Project (Debian)

Proyecto final donde se simula un servidor Debian comprometido. El objetivo es realizar análisis forense, recopilar evidencias, corregir vulnerabilidades y aplicar hardening siguiendo buenas prácticas.

## Fase 1 — Análisis forense y hardening
### Hallazgos
- No se detectaron usuarios sospechosos con privilegios root (solo UID 0: root).
- No se identificaron procesos anómalos ni malware en ejecución.
- `chkrootkit` reportó falsos positivos (Ruby/LibreOffice) y actividad normal de NetworkManager.

### Vulnerabilidades detectadas y mitigación
- **SSH inseguro:** Permitía login de root y autenticación por contraseña.  
  **Mitigación:** `PermitRootLogin prohibit-password` y `PasswordAuthentication no`.
- **MariaDB mal configurado:** root con autenticación por contraseña y usuario genérico `user` con privilegios completos.  
  **Mitigación:** root con `unix_socket` y eliminación del usuario `user`.
- **WordPress con permisos 777:** riesgo crítico de modificación y ejecución de código.  
  **Mitigación:** archivos 644, directorios 755 y `wp-config.php` 600.
- **Apache con listado de directorios:** `Options Indexes`.  
  **Mitigación:** `Options -Indexes +FollowSymLinks`.

## Evidencias
Incluye scripts y archivos de evidencias/hashes generados durante el análisis.

## Próximas fases
- **Fase 2:** detectar y corregir una vulnerabilidad adicional (escaneo + explotación controlada).
- **Fase 3:** plan de respuesta a incidentes (NIST) y SGSI basado en ISO 27001.
