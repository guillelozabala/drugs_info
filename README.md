# The role of information in illegal drug markets

This repository contains the code to replicate the results of the paper.

\*\***⚠️ This is a working project. The structure, code, and documentation are subject to regular changes, and some parts may be incomplete or disorganized ⚠️**\*\*

## Table of Contents
1. [Introduction](#introduction)
2. [Data](#data)
3. [Analysis](#code)
4. [Results](#results)
5. [References](#references)

## Introduction
TBA

## Data

So far I'm mostly working with data from the Antenne Amsterdam series, a collection of annual reports published jointly by the [Hogeschool van Amsterdam (HvA)](https://www.hva.nl/) and [Jellinek](https://www.jellinek.nl/). The series dates back to 1993, but only the reports from 2003 onwards have been digitized. They typically include the following information:

1. A panel study based on individual interviews with a group of insiders from various nightlife scenes that provides a qualitative sense of trends. Another component of the panel study focuses on vulnerable young people.
2. A survey on substance use. Depending on the report, the survey may cover groups such as school-aged adolescents, young clients of youth support services, coffeeshop customers, pubgoers, amateur football players, or clubbers, ravers, and festivalgoers.
3. Data from testing facilities, including information on the purity and prices of drug samples submitted, categorized by substance.

The script *antenne_reports_utils.py* includes several functions that obtain, detect and convert to *.csv* all this information. The reports are scraped from the [HvA repository](https://www.hva.nl/praktisch/algemeen/etalage/antenne/amsterdam/antenne-amsterdam.html). The data section of these documents is converted to *.png* files that can then be processed by this [table detection model](https://huggingface.co/microsoft/table-transformer-detection), which provides the boundaries (tensors) of each individual table. The tables are converted to *.csv* files using [Tabula](https://pypi.org/project/tabula-py/). The results of this process can still be improved upon.

Some parts of these data are cleaned in *antenne_reports_cleaning.py*.

Additional data regarding the presence of drug-related news is obtained in the script *red_alerts_scraper.py*, which scraps [De Telegraaf archief](https://www.telegraaf.nl/archief). 

## Analysis

So far the analysis consists of a series of plots depicting some trends. These plots can be obtained by running *descriptive_plots.R*

## Results
TBA

## References
TBA