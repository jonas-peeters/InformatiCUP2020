# Neural Network Model

## Models:
* Pathogen Prioritizer (PP)
* Pathogen Action Selector (PAS)
* Pathogen Action City Selector (PACS)
* City Selector (CS)
* City Action Selector (CAS)



## Pathogen Proritizer (PP)
### Input:
* Available points

Information about pathogen:
* Infectivity
* Mobility
* Duration
* Lethality
* Vaccine developing
* Medication developing
* Vaccine available
* Medication available

* Number of cities that have vaccine
* Number of cities that have medication

Information about cities:
* Number of affected cities
* Connection strength of affected cities (sum)
* Population of affected cities (sum)

### Output:
How many resources should this pathogen get



## Pathogen Action Selector (PAS)
### Input:
* Available points

Information about pathogen:
* Infectivity
* Mobility
* Duration
* Lethality
* Vaccine available
* Medication available

* Number of cities that have vaccine
* Number of cities that have medication

Information about cities:
* Number of affected cities
* Connection strength of affected cities (sum)
* Population of affected cities (sum)

### Output
One-Hot which action should be taken



## Pathogen Action City Selector (PACS)
### Input
Information about action:
* Want to deploy vaccine
* Want to deploy medicine

Information about pathogen:
* Infectivity
* Mobility
* Duration
* Lethality

Information about city:
* Population
* Economy
* Government
* Hygiene
* Awareness
* 13 * Connection Strength
* Infected
* Medication is deployed
* Vaccine is deployed

### Output:
Priority



## City Action Selector (CAS)
### Input:
Information about city:
* Population
* Economy
* Government
* Hygiene
* Awareness
* 13 * Connection Strength

Events:
* Medications deployed
* Vaccines deployed
* Infected
* Quarantine
* Economic crisis
* Large scale panic
* Anti vaccination
* Uprising

### Output:
* Priority
* One-Hot which action
