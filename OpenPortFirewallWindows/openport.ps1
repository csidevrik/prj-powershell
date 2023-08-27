New-NetFirewallRule -DisplayName "Docker Port 5000" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
