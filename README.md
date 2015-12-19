# DZ_LRS
Utilities for the creation and manipulation of Oracle Spatial LRS geometries.
For the most up-to-date documentation see the auto-build  [dz_lrs_deploy.pdf](https://github.com/pauldzy/DZ_LRS/blob/master/dz_lrs_deploy.pdf).

## Installation
Simply execute the deployment script into the schema of your choice.  Then execute the code using either the same or a different schema.  All procedures and functions are publically executable and utilize AUTHID CURRENT_USER for permissions handling.

Please note that the [Oracle Spatial Linear Referencing System](https://docs.oracle.com/database/121/SPATL/sdo_lrs_concepts.htm#SPATL060) requires the full Oracle Spatial and Graph license.  Please verify your rights to utilize LRS functions before any use in production.
