#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%F_%H%M%S)"
OUT="evidencia_${HOSTNAME}_${TS}.txt"
HASHOUT="hashes_${HOSTNAME}_${TS}.txt"

# Requiere root para leer ciertos ficheros/logs
if [[ "${EUID}" -ne 0 ]]; then
  echo "Ejecuta como root: sudo ./recolectar_evidencias.sh"
  exit 1
fi

# Funcion para secciones bonitas
section (){
 echo
 echo "======================================================================="
 echo "$1"
 echo "======================================================================="
}

# Cabecera
{
 echo "Informe de recoleccion de evidencias (solo lectura)"
 echo "Host: $(hostname -f 2>/dev/null || hostname)"
 echo "Fecha: $(date -R)"
 echo "Usuario ejecutor: $(whoami)"
 echo "Kernel: $(uname -a)"
} > "$OUT"

section "1) Contexto del sistema" >> "$OUT"
{
  echo "[date] $(date)"
  echo
  echo "[uptime]"
  uptime || true
  echo 
  echo "[hostnamectl]"
  hostnamectl 2>/dev/null || true
  echo
  echo "[ip a]"
  ip a || true
  echo
  echo "[ip r]"
  ip r || true
} >> "$OUT"

section "2) Usuarios, sesiones y privilegios" >> "$OUT"
{
  echo "[who]"
  who || true
  echo
  echo "[last -n 30]"
  last -n 30 2>/dev/null || true
  echo
  echo "[Usuarios con UID >= 1000]"
  awk -F: '$3 >= 1000 {print $1 " UID=" $3 " HOME=" $6 " SHELL=" $7}' /etc/passwd || true
  echo
  echo "[Grupos del usuario debian (si existe)]"
  id debian 2>/dev/null || true
  echo
  echo "[Sudoers: NOPASSWD]"
  grep -Rni "NOPASSWD" /etc/sudoers /etc/sudoers.d 2>/dev/null || echo "No encontrado"
} >> "$OUT"

section "3) Servicios activos, puertos y procesos" >> "$OUT"
{
  echo "[ss -tulpn]"
  ss -tulpn || true
  echo
  echo "[systemctl --type=service (running)]"
  systemctl list-units --type=service --state=running --no-pager 2>/dev/null || true
  echo
  echo "[ps aux --sort=-%cpu | head -n 25]"
  ps aux --sort=-%cpu | head -n 25 || true
} >> "$OUT"

section "4) SSH: configuracion y evidencias" >> "$OUT"
{
  echo "[sshd_config (directivas clave)]"
  if [[ -f /etc/ssh/sshd_config ]]; then
    egrep -n '^(PermitRootLOgin|PasswordAuthentication|PubkeyAuthentication|ChallengeREsponseAuthentication|UsePAM|AllowUsers|AllowGroups)\b' /etc/ssh/sshd_config || true
  else
    echo "No existe /etc/ssh/sshd_config"
  fi

  echo
  echo "[journalctl -u ssh (ultimas 200 lineas)]"
  journalctl -u ssh --no-pager -n 200 2>/dev/null || true

  echo
  echo "[journalctl -u sshd (ultimas 200 lineas)]"
  journalctl -u sshd --no-pager -n 200 2>/dev/null || true

  echo
  echo "[/root/.ssh/authorized_keys]"
  if [[ -f /root/.ssh/authorized_keys ]]; then
    ls -la /root/.shh/authorized_keys
    echo "---"
    sed -n '1,120p' /root/.ssh/authorized_keys
  else
    echo "No existe /root/.ssh/authorized_keys"
  fi
} >> "$OUT"

section "5) FTP (vsftpd): configuracion y estado" >> "$OUT"
{
  echo "[systemctl status vsftpd]"
  systemctl status vsftpd --no-pager 2>/dev/null || true
  echo
  echo "[vsftpd.conf (directivas clave)]"
  if [[ -f /etc/vsftpd.conf ]]; then
    egrep -n '^(listen=|listen_ipv6=|anonymous_enable=|local_enable=|write_enable=|chroot_local_user=|allow_writeable_chroot=|ssl_enable=|pasv_)\b' /etc/vsftpd.conf || true
  else
    echo "No existe /etc/vsftpd.conf"
  fi
} >> "$OUT"

section "6) Apache/WordPress: evidencia rapida y configuracion" >> "$OUT"
{
  echo "[systemctl status apache2]"
  systemctl status apache2 --no-pager 2>/dev/null || true
  echo
  echo "[apache2ctl -S]"
  apache2ctl -S 2>/dev/null || true

  echo
  echo "[Ruta web /var/www/html]"
  if [[ -d /var/www/html ]]; then
    ls -la /var/www/html | head -n 80
  else
    echo "No existe /var/www/html"
  fi

  echo
  echo "[wp-config.php permisos]"
  if [[ -d /var/www/html ]]; then
    CNT="$(find /var/www/html -type f -perm -777 2>/dev/null | wc -l || true)"
    echo "Cantidad: ${CNT}"
    find /var/www/html -type f -perm -777 2>/dev/null | head -n 50 || true
  else
    echo "No aplica"
  fi
} >> "$OUT"

section "7) Cron y persistencia" >> "$OUT"
{
  echo "[/etc/cron.d]"
  ls -la /etc/cron.d 2>/dev/null || true
  echo
  echo "[/etc/crontab]"
  if [[ -f /etc/crontab ]]; then
    sed -n '1,200p' /etc/crontab
  else
    echo "No existe /etc/crontab"
  fi
  echo
  echo "[systemd timers]"
  systemctl list-timers --all --no-pager 2>/dev/null || true
} >> "$OUT"

section "8) Historial root (si existe)" >> "$OUT"
{
  echo "[/root/.bash_history]"
  if [[ -f /root/.bash_history ]]; then
    ls -la /root/.bash_history
    echo "--- tail -n 200 ---"
    tail -n 200 /root/.bash_history || true
  else
    echo "No existe /root/.bash_history"
  fi

  echo
  echo "[/root/.mysql_history]"
  if [[ -f /root/.mysql_history ]]; then
    ls -la /root/.mysql_history
    echo "--- tail -n 200 ---"
    tail -n  200 /root/.mysql_history || true
  else
    echo "No existe /root/.mysql_history"
  fi
} >> "$OUT"

section "9) Hashes de integridad (archivos clave)" >> "$OUT"
{
  echo "Se generan hashes SHA256 en: ${HASHOUT}"
  echo "Archivos objetivo:"
  echo "- /etc/ssh/sshd_config"
  echo "- /etc/vsftpd.conf"
  echo "- /etc/apache2/apache2.conf"
  echo "- /etc/apache2/sites-enabled/*"
  echo "- /var/www/html/wp-config.php"
} >> "$OUT"

# Generar hashes (sin fallar si no existe algo)
{
  echo "Host: $(hostname)"
  echo "Fecha: $(date -R)"
  echo
  for f in \
    /etc/ssh/sshd_config \
    /etc/vsftpd.conf \
    /etc/apache2/apache2.conf \
    /var/www/html/wp-config.php
  do
    if [[ -f "$f" ]]; then
      sha256sum "$f"
    else
      echo "NO_EXISTE  $f"
    fi
  done

  if compgen -G "/etc/apache2/sites-enabled/*" > /dev/null; then
    for f in /etc/apache2/sites-enabled/*; do
      [[ -f "$f" ]] && sha256sum "$f" || true
    done
  else
    echo "NO_EXISTE  /etc/apache2/sites-enabled/*"
  fi
} > "$HASHOUT"

section "FIN" >> "$OUT"
{
  echo "Informe generado: $OUT"
  echo "Hashes generados:$HASHOUT"
} >> "$OUT"

echo " Listo:"
echo " - $OUT"
echo " - $HASHOUT"

