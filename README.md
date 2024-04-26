# WSI Data Pipeline

## Introduction
This containers is part of a data pipeline to automatically retrieve data from the Ontario Wastewater Surveillance Initiative (WSI) Data and Visualization Hub. Containerization of this data pipeline components offers environment isolation and reproducibility. Below follows a description and basic usage of each container. 

Container images are built by Github actions, and pushed to Github's container registry. You can find up-to-date built images [here](https://github.com/orgs/WDGPH/packages?repo_name=workflow-WSI).

## Retrieval Container
This container downloads ArcGIS online items from a specified url.

To use, `ARCGIS_USER` and `ARCGIS_PASSWORD` environment variables must be set for the container (credentials for WSI Data and Visualization Hub). It is strongly suggested that a secure key vault is utilized for this process and that credentials are rotated frequently. Additionally, the following arguments are required:

**1. `url`**  
ArcGIS Online item url. Changes with addition/removal of features to dataset requiring occasional updates.  
**Example**: `https://services6.arcgis.com/ghjer345tert/arcgis/rest/services/PROD_PHU_Base_Aggregated/FeatureServer/0/query`

**2. `output`**  
The filename where the output in CSV format will be written.  
**Example**: `wsi.csv`

## Processing Container
This container takes the CSV output from the retrieval container, and performs standardization and trend analysis on the data. There are disease target-specific outputs at both the sewershed and region-level. Sewershed weighting is required in order to perform region-level analyses. The container uses the following arguments:
    
**1. `input`**  
CSV file containing at minimum columns: sampleDate, siteName, mN1, mN2, mFluA, mFluB, and mBiomarker. Intention is to use the file that is output from the retrieval container for this.
**Example**: `wsi.csv`

**2. `weights`**  
CSV file with columns: Site, and Weight. The site column corresponds to siteName values in the `input`. Weights represents factor used for combing site-specific trends into a single regional trend. Weights are decimal numbers and should sum to 1. The weights may be set to be equal, or correspond to population weighting, sampling frequency, or any other user-determined criteria
**Example**: `weights.csv`

**3. `patch`**  
Optional CSV file with columns: Date, Site, and one or more of mN1, mN2, mFluA, mFluB, mBiomarker. Values in the patch file will add or overide any existing values in the primary input file. Useful, for adding historical data not present in WSI, or fixing erroneous data.
**Example**: `patch.csv`  
  
**4. `output_region_covid`**  
Optional output location for CSV file containing regional summary for SARS-CoV-2. No output will be generated if left blank.
**Example**: `output_region_covid.csv`  

**5. `output_region_flu_a`**  
Optional output location for CSV file containing regional summary for Influenza A. No output will be generated if left blank.
**Example**: `output_region_flu_a.csv`  

**6. `output_region_flu_b`**  
Optional output location for CSV file containing regional summary for Influenza B. No output will be generated if left blank.
**Example**: `output_region_flu_b.csv`  

**7. `output_covid`**  
Optional output location for CSV file containing site-specific SARS-CoV-2 data. No output will be generated if left blank.
**Example**: `output_covid.csv`  
    
**8. `output_flu_a`**  
Optional output location for CSV file containing site-specific Influenza A data. No output will be generated if left blank.
**Example**: `output_flu_a.csv`  

**9. `output_flu_b`**  
Optional output location for CSV file containing site-specific Influenza B data. No output will be generated if left blank.
**Example**: `output_flu_b.csv`  

## Pipeline Orchestration
This data pipeline can be orchestrated by a variety of tools that support containerized components, but has been developed and tested with [Kubeflow Pipelines](https://www.kubeflow.org/), which is based on [Argo Workflows](https://argoproj.github.io/argo-workflows/).

## Contributing
Dependency updates, documentation improvements, logging improvements, and additions of tests will enhance the usability and reliability of this project and are welcome contributions. 