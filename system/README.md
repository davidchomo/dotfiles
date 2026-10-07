System files (not stowed into $HOME). Install by hand with sudo, e.g.
`sudo install -Dm644 etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf /etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf && sudo systemctl daemon-reload`
