#!/bin/bash

# Create home dir and update vsftpd user db:
chown -R ftp:ftp /home/vsftpd/
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db

export FTP_USER=`awk 'NR==1 {print; exit}' /etc/vsftpd/virtual_users.txt`
export FTP_PASS=`awk 'NR==2 {print; exit}' /etc/vsftpd/virtual_users.txt`

# Set passive mode parameters:
if [ "$PASV_ADDRESS" = "**IPv4**" ]; then
    export PASV_ADDRESS=$(/sbin/ip route|awk '/default/ { print $3 }')
fi

echo "pasv_address=${PASV_ADDRESS}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_max_port=${PASV_MAX_PORT}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_min_port=${PASV_MIN_PORT}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_addr_resolve=${PASV_ADDR_RESOLVE}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_enable=${PASV_ENABLE}" >> /etc/vsftpd/vsftpd.conf
echo "file_open_mode=${FILE_OPEN_MODE}" >> /etc/vsftpd/vsftpd.conf
echo "local_umask=${LOCAL_UMASK}" >> /etc/vsftpd/vsftpd.conf
echo "xferlog_std_format=${XFERLOG_STD_FORMAT}" >> /etc/vsftpd/vsftpd.conf
echo "reverse_lookup_enable=${REVERSE_LOOKUP_ENABLE}" >> /etc/vsftpd/vsftpd.conf
echo "pasv_promiscuous=${PASV_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf
echo "port_promiscuous=${PORT_PROMISCUOUS}" >> /etc/vsftpd/vsftpd.conf

# Add ssl options
if [ "$SSL_ENABLE" = "YES" ]; then
	echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf
	echo "allow_anon_ssl=NO" >> /etc/vsftpd/vsftpd.conf
	echo "force_local_data_ssl=YES" >> /etc/vsftpd/vsftpd.conf
	echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf
	echo "ssl_tlsv1=YES" >> /etc/vsftpd/vsftpd.conf
	echo "ssl_sslv2=NO" >> /etc/vsftpd/vsftpd.conf
	echo "ssl_sslv3=NO" >> /etc/vsftpd/vsftpd.conf
	echo "require_ssl_reuse=YES" >> /etc/vsftpd/vsftpd.conf
	echo "ssl_ciphers=HIGH" >> /etc/vsftpd/vsftpd.conf
	echo "rsa_cert_file=/etc/vsftpd/cert/$TLS_CERT" >> /etc/vsftpd/vsftpd.conf
	echo "rsa_private_key_file=/etc/vsftpd/cert/$TLS_KEY" >> /etc/vsftpd/vsftpd.conf
fi

# stdout server info:
cat << EOB
	*************************************************
	*                                               *
	*    Docker image: fauria/vsftpd                *
	*    https://github.com/fauria/docker-vsftpd    *
	*                                               *
	*************************************************

	SERVER SETTINGS
	---------------
	· FTP User: $FTP_USER
	· FTP Password: $FTP_PASS
	· Log File Path: /var/log/vsftpd.log
EOB

# Run vsftpd in background
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf

# Create log file if it doesn't exist so tail command succeeds. Usually, this file
# isn't created until there's some FTP activity
touch /var/log/vsftpd.log
tail -f /var/log/vsftpd.log
