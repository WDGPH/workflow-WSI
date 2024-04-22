import argparse
import requests
import pandas as pd
import os
import logging

# Argument parser
def parse_args():
  parser = argparse.ArgumentParser(
    description='Extract a feature set from an ArcGIS Online URL')
  
  parser.add_argument(
    '--url',
    help = "ArcGIS Online url for item",
    required = True,
    type = str)
  
  parser.add_argument(
    '--output',
    help = "Filename to write output to",
    required = True,
    type = str)
  
  return parser.parse_args()

# Main function to extract and output data from PHO WTISEN
def main(features_url, output):
  
  # Load credentials and remove environment variables
  username = os.getenv('ARCGIS_USER')
  if username is not None:
    logging.info("ARCGIS_USER environment variable found")
    os.environ.pop('ARCGIS_USER', None)
  else:
    raise ValueError("ARCGIS_USER environment variable not found.")
  
  password = os.getenv('ARCGIS_PASSWORD')
  if password is not None:
    logging.info("ARCGIS_PASSWORD environment variable found")
    os.environ.pop('ARCGIS_PASSWORD', None)
  else:
    raise ValueError("ARCGIS_PASSWORD environment variable not found.")
  
  logging.info("Generating ArcGIS API token")
  token = requests.post(
    url = 'https://www.arcgis.com/sharing/rest/generateToken',
    data = {
      'f': 'json',
      'username': username,
      'password': password,
      'referer': 'https://www.arcgis.com',
      'expiration': 60, # minutes
    }).json()['token']

  # Set up pagination
  batch_size = 1000 
  offset = 0
  all_records = []
  continue_pagination = True

  logging.info(f"Retrieving data in batch sizes of {batch_size} from {features_url} in JSON format")

  while continue_pagination:
    logging.info(f"Retrieving data batch {(offset//batch_size) + 1}")

    # Fetch batch of records
    response = requests.get(
      url = features_url,
      params= {
        'f': 'json',
        'where': '1=1',
        'outFields': '*',
        'resultOffset': offset,
        'resultRecordCount': batch_size,
        'token': token
    }).json()

    # Add records to all_records list
    all_records.extend(response.get('features', []))

    # Check if exceededTransferLimit is true to determine if pagination continues
    continue_pagination = response.get('exceededTransferLimit', False)

    # Increment offset
    offset += batch_size

  logging.info("All data retrieved")
  logging.info("Converting JSON to tabular format")
  features = pd.DataFrame([record['attributes'] for record in all_records])

  rows, columns = features.shape
  logging.info(f"Data contains {rows} rows and {columns} columns")

  logging.info(f"Exporting data as {output}")
  features.to_csv(output, index = False)


if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', level=logging.INFO)
  
  # Parse and unpack keyword arguments
  main(**vars(parse_args()))
  logging.info("Done")