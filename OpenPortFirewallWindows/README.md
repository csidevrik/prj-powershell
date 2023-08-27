Abrir puerto del firewall de windows
======================================

Al correr docker on windows es necesario abrir los puertos de firewall por donde van a correr las aplicaciones de nuestros contenedores.

```powershell
New-NetFirewallRule -DisplayName "Docker HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Docker Port 5000" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```
BIBLIOGRAFIA
-------------------------------------------------------
- [OpenPortFirewallWindows](https://serverfault.com/questions/883266/powershell-how-open-a-windows-firewall-port)
- [superuser] (https://superuser.com/questions/842698/how-to-open-a-firewall-port-in-windows-using-power-shell)
