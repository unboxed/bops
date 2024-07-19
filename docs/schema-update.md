# Updating the ODP schema

Periodically we need to make changes based on a new release of the [ODP schema][]. Several files need to be updated as part of this process.

[Example PR][]

- Create new version directories at `engines/bops_api/schemas/odp/$VERSION/` and `engines/bops_api/spec/fixtures/examples/odp/$VERSION/`
- Update the version number and source URL in `engines/bops_api/lib/bops_api/schemas.rb`
- Save a copy of the new `schema.json` as `engines/bops_api/schemas/odp/$VERSION/submission.json`
- Copy the other JSON files from the previous version to the current version: we manage these ourselves separately from the main release cycle
- Retrieve example responses from the [ODP schema examples], using the correct tag and subdirectory for the new version (e.g., tag `v3.1.4` subdirectory `v3.1.4/examples/`)
  - Note that these do not all match our naming scheme but mostly do correspond in a logical way; e.g., their `lawfulDevelopmentCertificate/existing.json` becomes our `validLawfulDevelopmentCeriticateExisting.json` and so on
  - If a file that exists in the previous version's examples does not exist in their repository, copy it from our previous version
- Update the list of tested versions in `engines/bops_api/spec/controllers/v2/planning_applications_controller_spec.rb`
- Update the Swagger documentation
- Now all your tests will pass and there will certainly not be any unexpected problems that arise with the new version that you have to fix (TODO double check this)

[ODP schema]: https://github.com/theopensystemslab/digital-planning-data-schemas
[Example PR]: https://github.com/unboxed/bops/pull/1886
[ODP schema examples]: https://github.com/theopensystemslab/digital-planning-data-schemas/tree/v0.7.0/v0.7.0/examples
