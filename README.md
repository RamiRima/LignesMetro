# LignesMetro
- Le but de ce projet est de prendre la base données des lignes de métro de Paris en format .csv et les transformer en .xml et puis les représenter dans un fichier .svg.
#Utilisation
    -`pyhton csv_to_xml.py` demarre le script qui va utiliser le ficher `base_ratp.csv` pour generer le xml `base_ratp.xml`
    - `xmllint --schema validate.xsd base_ratp.xml --noout` valide le ficher xml avec le schema `validate.xsd`
    - `java -jar saxon-he-10.3.jar -s:base_ratp.xml -xsl:transofrm.xsl -o:metro.svg` pour faire la transformation vers svg (output = `metro.svg`)
