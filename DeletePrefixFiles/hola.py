import os
import fnmatch

def get_files_pdf(path):
    files_pdf = []
    for (root, dirs, files) in os.walk(path):
        for filename in files:
            if fnmatch.fnmatch(filename, '*.pdf'):
                file_complete = os.path.join(root,filename)
                files_pdf.append(file_complete)
                print(file_complete)
    
    return files_pdf

def main():
    directorio = '/home/adminos/OneDriveP/2A-JOB02-EMOVEP/2023/CONTRATOS/RE-EP-EMOVEP-2023-02/FACTURAS/SEP2'
    listdbs = get_files_pdf(directorio)

if __name__ == "__main__":
    main()