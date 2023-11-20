import argparse
import arcgis
import os
import logging

# Argument parser
def parse_args():
  parser = argparse.ArgumentParser(
    description='Extract a feature set from an ArcGIS Online item')
  
  parser.add_argument(
    'item_id',
    help = "ArcGIS Online item id",
    type = str)
  
  parser.add_argument(
    'output',
    help = "Filename to write output to",
    type = str)
  
  return parser.parse_args()


# Main function to extract and output data from ArcGIS Online
def main(item_id, output):
  if os.getenv('ARCGIS_USER') is not None:
    logging.info("ARCGIS_USER environment variable found")
  else:
    raise ValueError("ARCGIS_USER environment variable not found.")

  if os.getenv('ARCGIS_PASSWORD') is not None:
    logging.info("ARCGIS_PASSWORD environment variable found")
  else:
    raise ValueError("ARCGIS_PASSWORD environment variable not found.")
  
  logging.info("Connecting to ArcGIS Online")
  gis = arcgis.gis.GIS(
    username = os.getenv('ARCGIS_USER'),
    password = os.getenv('ARCGIS_PASSWORD'),
    verify_cert = False)
  
  logging.info("Logged in to ArcGIS Online as " + str(gis.properties.user.username))
  
  logging.info(f"Retrieving {item_id}")
  item = gis.content.get(item_id)
  
  logging.info("Extracting feature set")
  feature_set = item.layers[0].query()
  
  logging.info(f"Outputting feature set to {output}")
  feature_set.sdf.to_csv(output)


if __name__ == '__main__':
  logging.basicConfig(format='%(asctime)s %(message)s', datefmt='%Y-%m-%d %H:%M:%S', level=logging.INFO)
  
  # Parse and unpack keyword arguments
  main(**vars(parse_args()))
  
  logging.info("Done")