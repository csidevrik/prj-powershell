import pandas as pd

# Leer el archivo CSV
df = pd.read_csv('hosts.csv')

# Iterar sobre cada fila y construir el comando
for index, row in df.iterrows():
    name = row['name']
    ip_address = row['ip-address']
    colortype = row['colortype']
    command = f'add host name "{name}" ip-address "{ip_address}" color "{colortype}" --format json'
    print(command)