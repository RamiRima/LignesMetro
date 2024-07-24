import xml.etree.ElementTree as ET
import csv

# open the csv file
ratp = open("base_ratp.csv", newline='\n')
reader = csv.DictReader(ratp, delimiter=';')

rows = {}
# copying file contents into a list
for row in reader:
    # save info only in one direction
    service_id = row['service_id']
    if(row['direction_id'] == '0'):
        # check if we're adding a new line or not
        if(service_id not in rows):
            rows[service_id] = {'short_name': row['service_short_name'],
                                'long_name_first': row['long_name_first'],
                                'long_name_last': row['long_name_last'],
                                'stops': []}

        row.pop('service_id')
        row.pop('route_id')
        row.pop('service_short_name')
        row.pop('long_name_first')
        row.pop('long_name_last')
        row.pop('direction_id')
        present = False
        for stop in rows[service_id]['stops']:
            if stop['station_id'] == row['station_id']:
                present = True
        if not present:
            rows[service_id]['stops'].append(row)

    if(int(row['stop_sequence']) == 1):
        for stop in rows[service_id]['stops']:
            if stop['station_id'] == row['station_id']:
                stop['end_point'] = True


# prepare the xml doc

root = ET.Element('metro')
lines = ET.SubElement(root, 'metro_lines')
stations = ET.SubElement(root, 'stations')

station_list = {}

# make list of stations and add it at the end of the file
for key in rows:
    for station in rows[key]['stops']:
        if(station['station_id'] not in station_list.keys()):
            station_list[station['station_id']] = []
            # this will make each dict in the list have a list of lines this station appears in

            stop = ET.SubElement(stations, 'station')
            stop.set('station_id', station['station_id'])

            # station details
            stop_name = ET.SubElement(stop, 'station_name')
            stop_name.text = station['station_name']
            stop_desc = ET.SubElement(stop, 'station_desc')
            stop_desc.text = station['station_desc']
            stop_lat = ET.SubElement(stop, 'station_lat')
            stop_lat.text = station['station_lat']
            stop_lon = ET.SubElement(stop, 'station_lon')
            stop_lon.text = station['station_lon']
        if(key not in station_list[station['station_id']]):
            station_list[station['station_id']].append(key)



def fork(parent, stops, index, service_id):
    fork = ET.SubElement(parent, 'fork')
    left = ET.SubElement(fork, 'left')
    right = ET.SubElement(fork, 'right')
    # get the forked sequence of stations
    # half into left and half into right
    stopl = {}
    stopr = {}
    try:
        while(stops[index]['stop_sequence'] == stops[index+1]['stop_sequence']):
            left_stop = ET.SubElement(left, 'station')
            right_stop = ET.SubElement(right, 'station')

            stopl = stops[index]
            stopr = stops[index+1]
            left_stop.set('station_id', stopl['station_id'])
            left_stop.set('stop_sequence', stopl['stop_sequence'])
            if(len(station_list[stopl['station_id']]) > 1):
                links = station_list[stopl['station_id']].copy()
                links.remove(service_id)
                left_stop.set('links', " ".join(links))
            left_stop.text = stopl['station_name']

            right_stop.set('station_id', stopr['station_id'])
            right_stop.set('stop_sequence', stopr['stop_sequence'])
            if(len(station_list[stopr['station_id']]) > 1):
                links = station_list[stopr['station_id']].copy()
                links.remove(service_id)
                right_stop.set('links', " ".join(links))
            right_stop.text = stopr['station_name']

            index += 2
    except IndexError:

        pass
    # check if the line combines back into one or stays split
    if 'end_point' in stopl:
        cont = right
    elif 'end_point' in stopr:
        cont = left
    else:
        return (index-1)

    for i in range(index, len(stops)):
        stop = ET.SubElement(cont, 'station')
        stop.set('station_id', stops[i]['station_id'])
        stop.set('stop_sequence', stops[i]['stop_sequence'])
        if(len(station_list[stops[i]['station_id']]) > 1):
            links = station_list[stops[i]['station_id']].copy()
            links.remove(service_id)
            stop.set('links', " ".join(links))
        stop.text = stops[i]['station_name']

    return i


for key in rows:
    # create line element and init its attributes/text
    metro_line = ET.SubElement(lines, 'line')
    metro_line.set('service_id', key)
    ET.SubElement(metro_line, 'short_name').text = rows[key]['short_name']
    ET.SubElement(
        metro_line, 'long_name_first').text = rows[key]['long_name_first']
    ET.SubElement(
        metro_line, 'long_name_last').text = rows[key]['long_name_last']

    stops = ET.SubElement(metro_line, 'stops')

    index = 0
    while(index < len(rows[key]['stops'])):
        no_fork = True
        station = rows[key]['stops'][index]
        try:
            # if 2 stations have the same 'stop_sequence' --> line splits
            if(station['stop_sequence'] == rows[key]['stops'][index+1]['stop_sequence']):
                idx = fork(stops, rows[key]['stops'], index, key)
                no_fork = False
        except IndexError:
            # exception is when we're at the last one and the index+1 call fails
            pass
        if no_fork:
            stop = ET.SubElement(stops, 'station')
            stop.set('station_id', station['station_id'])
            stop.set('stop_sequence', station['stop_sequence'])
            if(len(station_list[station['station_id']]) > 1):
                links = station_list[station['station_id']].copy()
                links.remove(key)
                stop.set('links', " ".join(links))
            stop.text = station['station_name']
        else:
            index = idx
        index += 1


tree = ET.ElementTree(root)
ET.indent(tree, space='\t')

with open('base_ratp.xml', 'wb') as file:
    tree.write(file)
