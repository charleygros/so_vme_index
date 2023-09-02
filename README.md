# VME index computation

This repository contains the Python code used to compute the VME indexes presented at [SCAR 2022](https://scar2022.org/), abstract #533:
```
A multi-criteria index for identifying Vulnerable Marine Ecosystems in the Southern Ocean

Authors: Charley Gros, Jan Jansen, Candice Untiedt, Tabitha Pearman, Rachel Downey, David K. A. Barnes, David A. Bowden, Dirk C. Welsford, Nicole A. Hill
```
![text15247-6-4-1-6](https://user-images.githubusercontent.com/14353425/183558367-3a14a498-d6da-448c-bb72-cdeec325f57b.png)

## Getting Started

This repo has been tested with Python 3.8. Follow the steps below to use this repo:

1. Clone project: `git clone https://github.com/charleygros/so_vme_index`
2. Create virtual environment and install packages:
	```
	cd so_vme_index/
	virtualenv -p python3.8 .env
	source .env/bin/activate
	pip install -r requirements.txt
	```
3. Check the sections below for data preparation and index computation.

## Data preparation

Example data is provided, see `/example_data`. Please follow how these `csv` files are organised.

- `abundance_data.csv`: contains the percentage cover of each studied morpho-taxon inside each grid-cell (see `cellID`): values between 0 and 100. The `area` column contains the sampling effort (e.g. in m^2) inside each grid cell.

![image](https://user-images.githubusercontent.com/14353425/183559048-d751d7d8-3620-46f6-939a-0f3cccc414a0.png)

- `vulnerability_scores.csv`: contains the vulnerability scores for each vulnerability criterion.

![image](https://user-images.githubusercontent.com/14353425/183559181-331518b7-8db3-455b-a5d3-78133608c4c9.png)

## Computation

The code is located in `vme_index/compute_vme_index.py`. To see the different parameters' requirements, run:
```
python vme_index/compute_vme_index.py -h
```

To run the command with the `example_data`:
```
python vme_index/compute_vme_index.py -i example_data/abundance_data.csv -s example_data/vulnerability_scores.csv -o results_example_data.csv
```

The output file (here `results_example_data.csv`) contains the abundance-based and the richness-based VME index for each `cellID`.
