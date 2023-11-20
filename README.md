# WSI Data Pipeline

## Introduction
This containers is part of a data pipeline to automatically retrieve data from the Ontario Wastewater Surveillance Initiative (WSI) Data and Visualization Hub. Containerization of this data pipeline components offers environment isolation and reproducibility. Below follows a description and basic usage of each container. 

Container images are built by Github actions, and pushed to Github's container registry. You can find up-to-date built images [here](https://github.com/orgs/WDGPH/packages?repo_name=workflow-WSI).

## Retrieval Container
This container utilizes the [ArcGIS API Python Package](https://developers.arcgis.com/python/guide/install-and-set-up/) to authenticate to ArcGIS online, which is then used to download resources by item ID.

To use, `ARCGIS_USER` and `ARCGIS_PASSWORD` environment variables must be set for the container (credentials for WSI Data and Visualization Hub). It is strongly suggested that a secure key vault is utilized for this process and that credentials are rotated frequently. Additionally, the following arguments are required:

**1. `item_id`**  
ArcGIS Online item id. Changes with addition/removal of features to dataset requiring occasional updates.
**Example**: `1a111aa1a1aa1a1aaaa1a111aa1a1aa1`

**2. `output`**  
The filename where the output will be written.
**Example**: `wsi.csv`

## Pipeline Orchestration
This data pipeline can be orchestrated by a variety of tools that support containerized components, but has been developed and tested with [Kubeflow Pipelines](https://www.kubeflow.org/), which is based on [Argo Workflows](https://argoproj.github.io/argo-workflows/).

## Contributing
Dependency updates, documentation improvements, logging improvements, and additions of tests will enhance the usability and reliability of this project and are welcome contributions. 