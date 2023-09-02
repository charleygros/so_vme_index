import os
import argparse
import numpy as np
import pandas as pd


def get_parser():
    parser = argparse.ArgumentParser(add_help=False)

    # MANDATORY ARGUMENTS
    mandatory_args = parser.add_argument_group('MANDATORY ARGUMENTS')
    mandatory_args.add_argument('-i', '--ifname', required=True, type=str,
                                help='Input CSV filename. File containing the percentage cover of each VME indicator'
                                     ' morpho-taxon. Each row represents a grid cell.')
    mandatory_args.add_argument('-s', '--sfname', required=True, type=str,
                                help='Vulnerability score CSV filename. Each row contains the scores of a VME indicator'
                                     ' morpho-taxon. Each column is a criterion.')
    mandatory_args.add_argument('-o', '--ofname', required=True, type=str,
                                help='Output CSV filename. Each row represents a grid cell, with the VME indexes values.')

    # OPTIONAL ARGUMENTS
    optional_args = parser.add_argument_group('OPTIONAL ARGUMENTS')
    optional_args.add_argument('-c', '--criteria', required=False, type=str, default=None,
                               choices=['ccamlr', None],
                               help='Method to aggregate the criteria scores to compute the vulnerability score.'
                                    ' If None, then the criteria scores are all aggreated using the quadratic mean.')
    optional_args.add_argument('-h', '--help', action='help', default=argparse.SUPPRESS,
                               help='Shows function documentation.')

    return parser


def read_csv_as_df(fname_csv):
    return pd.read_csv(fname_csv)


def quadratic_mean(x):
    vals = [xx for xx in x if str(xx) != 'nan']
    return np.sqrt(np.sum([vv * vv for vv in vals]) / len(vals))


def compute_vulnerability_score(df_scores, agg_method):
    if agg_method == "ccamlr":
        df_scores["tmp"] = df_scores[['Longevity', 'Slow growth']].mean(axis=1)
        lst_criteria_agg = ['Habitat forming', 'Rare or unique', 'Fragility', 'Larval dispersion', 'Sessility', 'tmp']
    else:
        lst_criteria_agg = [c for c in df_scores.keys() if not c in ["morpho_taxon"]]

    df_scores["vulnerability_score"] = df_scores[lst_criteria_agg].apply(quadratic_mean, axis=1)

    return df_scores[["morpho_taxon", "vulnerability_score"]]


def compute_vme_index(df_abd, df_scores, criteria=None):
    print("\nAbundance data ...")
    print(df_abd.head())

    print("\nComputing vulnerability scores ...")
    df_vulnerability = compute_vulnerability_score(df_scores, agg_method=criteria)
    print(df_vulnerability.head())

    lst_vme_species = df_vulnerability["morpho_taxon"].to_list()
    # Get abundance data of the species of interest
    df_abd_vme = df_abd[["cellID", "area"] + lst_vme_species]
    # Get presence-absence data of the species of interest
    df_richness_vme = df_abd_vme.copy()
    df_richness_vme[lst_vme_species] = df_richness_vme[lst_vme_species].astype(bool).astype(float)

    # Modulate data with the vulnerability score
    for sp in lst_vme_species:
        vulnerability_score = df_vulnerability[df_vulnerability["morpho_taxon"] == sp]["vulnerability_score"].values[0]
        df_abd_vme[sp] *= vulnerability_score
        df_richness_vme[sp] *= vulnerability_score

    # Abundance-based VME index: Aggregate across VME indicator morpho taxa
    print("\nAbundance-based VME index ...")
    df_abd_vme["abundance_vme_index"] = df_abd_vme[lst_vme_species].sum(axis=1)

    # Richness-based VME index: Aggregate across VME indicator morpho taxa
    print("\nRichness-based VME index ...")
    df_richness_vme["vme_index"] = df_richness_vme[lst_vme_species].sum(axis=1)
    # Standardise richness to account for differing sampling effort
    df_richness_vme['vme_index'] = np.log(df_richness_vme['vme_index'])
    df_richness_vme['ln_area'] = np.log(df_richness_vme['area'])
    df_richness_vme['richness_vme_index'] = df_richness_vme['vme_index'] / df_richness_vme['ln_area']

    # Generate output
    print("\nGenerating the results ...")
    df_out = pd.merge(left=df_abd_vme[["cellID", "abundance_vme_index"]],
                      right=df_richness_vme[["cellID", "richness_vme_index"]],
                      on="cellID")
    print(df_out.head())
    return df_out


def main():
    parser = get_parser()
    args = parser.parse_args()

    # Read data
    df_abd = read_csv_as_df(fname_csv=args.ifname)
    df_scores = read_csv_as_df(fname_csv=args.sfname)

    # Main function
    df_out = compute_vme_index(df_abd, df_scores, args.criteria)

    # Save results as CSV
    if os.path.isfile(args.ofname):
        print("\nWARNING: Overwritting the output file {} ...".format(args.ofname))
    print("\nSaving results in {} ...".format(args.ofname))
    df_out.to_csv(args.ofname, index=False)


if __name__ == "__main__":
    main()
