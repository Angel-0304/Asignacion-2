# El OpenSSH de Kali ofrece tantos algoritmos que el IOL cierra la conexion;
# se fija la lista exacta que soporta el IOL
cat >> ~/.ssh/config << 'EOF'
Host 10.23.56.1 10.23.56.130
    KexAlgorithms diffie-hellman-group14-sha1
    HostKeyAlgorithms ssh-rsa
    MACs hmac-sha1
    Ciphers aes128-ctr
EOF

# Pruebas de SSH (solo usuario local 'admin')
ssh admin@10.23.56.1      # R-AAA
ssh admin@10.23.56.130    # SW-AAA
