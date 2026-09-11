# Azure Static Web Apps CI/CD: Core Concepts And Interview Questions

This guide covers the CI/CD delivery pattern used for the AADData.com portfolio website. It is intentionally separate from the Databricks workflow notes: Databricks Workflows schedule data processing, while this GitHub Actions workflow builds and deploys the public website.

## 1. Project Delivery Summary

> I deployed the AADData.com portfolio as an Azure Static Web App connected to GitHub. A GitHub Actions workflow monitors the `main` branch and deploys the static content from the repository's `website` folder. Pull requests targeting `main` create a pre-production environment so that I can review changes before they are merged. The workflow uses an Azure Static Web Apps deployment token stored as a GitHub Actions secret, so no deployment credential is committed to the repository.

```text
Local change -> Git branch -> GitHub pull request -> Azure preview environment
                                                   |
                                           review and merge
                                                   |
                                           main branch push
                                                   |
                                      Azure Static Web Apps production
                                                   |
                                         https://www.aaddata.com
```

## 2. Current AADData.com Configuration

| Component | Current implementation | Why it matters |
| --- | --- | --- |
| Source repository | `AADData/MutualFund_DataEngg_Platform` | GitHub is the version-controlled deployment source. |
| Website source | `website/` | The static HTML, CSS, diagrams, and assets live here. |
| Production branch | `main` | A push to `main` starts the production deployment workflow. |
| Workflow file | `.github/workflows/azure-static-web-apps-blue-river-0b1cabe00.yml` | Defines the trigger, build, deployment, and PR cleanup steps. |
| Azure resource | Azure Static Web App `swa-aaddata-portfolio` | Hosts the site and custom domain. |
| Production domain | `https://www.aaddata.com` | Public employer/recruiter-facing site. |
| Deployment credential | GitHub Actions secret `AZURE_STATIC_WEB_APPS_API_TOKEN_BLUE_RIVER_0B1CABE00` | Allows the workflow to deploy without putting a token in Git. |
| GitHub integration token | `${{ secrets.GITHUB_TOKEN }}` | Lets the workflow integrate with GitHub, including pull-request status/comments. |

## 3. Read The Current Workflow

The workflow is at `.github/workflows/azure-static-web-apps-blue-river-0b1cabe00.yml`.

### Trigger section

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main
```

Meaning:

- A commit pushed to `main` starts a production deployment.
- A pull request opened or updated against `main` starts a pre-production deployment.
- `synchronize` means a new commit was pushed to the existing pull-request branch.
- A closed pull request triggers the cleanup job.

### Deployment job

```yaml
jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
```

Meaning:

- A **job** is a group of steps executed in a GitHub Actions runner.
- `ubuntu-latest` is a Microsoft-hosted Linux runner managed by GitHub Actions.
- The condition avoids trying to deploy a preview when the pull request is being closed.

### Checkout and Azure deployment steps

```yaml
- uses: actions/checkout@v3
  with:
    submodules: true
    lfs: false

- uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_BLUE_RIVER_0B1CABE00 }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    action: "upload"
    app_location: "./website"
    api_location: ""
    output_location: "."
```

Meaning:

- `actions/checkout` downloads the selected Git commit onto the runner.
- `Azure/static-web-apps-deploy` is the Azure GitHub Action that builds, packages, and deploys the app.
- `app_location: "./website"` points to the AADData.com source folder.
- `output_location: "."` means the deployable static files are already in the `website` folder. This is appropriate because the site uses plain HTML, CSS, and assets, rather than a framework build that creates `dist` or `build`.
- `api_location: ""` means this deployment has no Azure Functions API.
- `action: "upload"` tells the action to upload the website to Azure Static Web Apps.

### Pull-request environment cleanup

```yaml
close_pull_request_job:
  if: github.event_name == 'pull_request' && github.event.action == 'closed'
  ...
  action: "close"
```

Meaning:

- When the pull request is merged or closed, Azure removes the temporary pull-request environment.
- This does **not** delete source code or the production website. It closes only the Azure preview environment for that pull request.

## 4. Core CI/CD Concepts

### Continuous Integration (CI)

CI is the practice of integrating changes frequently and automatically validating them. In a mature website pipeline, CI might include HTML validation, automated tests, link checking, accessibility checks, linting, and a build.

The current AADData.com workflow checks out and deploys the static site. It has a basic build/deploy stage but does not yet have explicit quality-gate steps such as a linter or automated browser test.

### Continuous Deployment (CD)

CD automatically releases a validated commit to an environment. In this project:

- A pull request deploys a preview environment.
- A merge to `main` deploys the production site.

### Infrastructure as Code (IaC) versus pipeline as code

The workflow YAML is **pipeline as code**: it defines how the application is built and deployed. It is not full Azure infrastructure as code. Terraform, Bicep, ARM templates, or Pulumi would define resources such as the Static Web App, storage accounts, and SQL Database.

### GitHub Actions workflow, job, step, runner, and action

| Term | Meaning in this project |
| --- | --- |
| Workflow | The YAML file that controls the AADData.com deployment. |
| Job | `build_and_deploy_job` or `close_pull_request_job`. |
| Step | A single job action, such as checkout or deployment. |
| Runner | The temporary `ubuntu-latest` machine that executes the job. |
| Action | Reusable automation, such as `actions/checkout` or `Azure/static-web-apps-deploy`. |

### Secret

A secret is a sensitive value stored in GitHub rather than source code. The Azure deployment token is stored as a repository secret and referenced with `${{ secrets.SECRET_NAME }}`. GitHub redacts recognized secrets in logs, but a secret must still never be printed, copied into code, or stored in a text file.

## 5. Recommended Release Process For AADData.com

Use pull requests for every user-facing change. This gives you a review point before production changes.

```text
1. Create a short-lived feature branch
2. Make and test the local change
3. Push the branch to GitHub
4. Open a pull request targeting main
5. Review the Azure preview URL on the pull request
6. Merge the pull request only when it is correct
7. GitHub Actions deploys main to www.aaddata.com
8. Check the production site and deployment history
```

Example commands:

```powershell
git switch -c codex/website-update
git add website/index.html
git commit -m "Describe the website change"
git push -u origin codex/website-update
```

Then create a pull request in GitHub from `codex/website-update` into `main`.

### Protect the production branch

In GitHub repository settings, create a branch protection rule or ruleset for `main`:

- Require a pull request before merging.
- Block force pushes.
- Do not require an approving reviewer while you are the sole maintainer; otherwise you can block yourself from merging.
- Add required status checks later when the workflow includes tests.

This does not prevent you from releasing. It prevents an accidental direct push from immediately changing the public site.

## 6. Interview Questions And Answers

### Q1. Describe the CI/CD setup you used for AADData.com.

**Answer:** The portfolio is hosted on Azure Static Web Apps and connected to GitHub. I use a GitHub Actions YAML workflow that triggers for changes to `main` and for pull requests targeting `main`. It checks out the repository and uses the Azure Static Web Apps deployment action to publish the static content from the `website` folder. Pull requests give me a preview environment for review; merging to `main` promotes the approved change to the production website.

### Q2. What is the difference between CI and CD in your implementation?

**Answer:** CI is the integration and validation side of the pipeline. CD is the release side. My current workflow automatically deploys the static app and creates PR previews. It is a practical CI/CD baseline, but I would add explicit linting, link checks, and browser tests to make the CI quality gate stronger before treating it as a full enterprise pipeline.

### Q3. Why store the deployment token as a GitHub secret?

**Answer:** The deployment token authorizes Azure Static Web Apps deployment. It must be available to the workflow but must never be present in source control, local documentation, screenshots, or browser output. A GitHub secret is encrypted, access-controlled, and referenced at runtime.

### Q4. What is the difference between the Azure deployment token and `GITHUB_TOKEN`?

**Answer:** The Azure Static Web Apps deployment token authorizes deployment to the Azure resource. `GITHUB_TOKEN` is automatically provided by GitHub Actions and is used for GitHub-side integration, such as pull-request status and comments. They serve different trust boundaries and should not be interchanged.

### Q5. What happens after a push to `main`?

**Answer:** GitHub detects the push event, starts the workflow on a hosted runner, checks out the commit, deploys the `website` folder to Azure Static Web Apps, and updates the production environment. The custom domain `www.aaddata.com` serves the new version after the deployment completes.

### Q6. What happens when you open a pull request against `main`?

**Answer:** The workflow runs for the pull request and Azure Static Web Apps creates a pre-production environment. GitHub posts a preview URL to the pull request. New commits to that branch update the same preview so I can review the final website before merging.

### Q7. Why use a pull-request preview rather than deploying straight to production?

**Answer:** It makes user-facing changes reviewable without exposing unfinished content on the live domain. It also provides a clear audit trail: the change, discussion, workflow result, preview, and eventual merge are all visible in GitHub.

### Q8. What is `app_location` and why is it `./website`?

**Answer:** `app_location` tells Azure Static Web Apps where the application source lives relative to the repository root. This repo has both data-engineering code and a website, so specifying `./website` prevents the action from trying to deploy the full project repository.

### Q9. What does `output_location: "."` mean here?

**Answer:** It is the final deployable content directory relative to `app_location`. Because AADData.com is plain static HTML, CSS, SVG, and image assets, there is no separate compiled build output. The current `website` folder itself is the deployable output.

### Q10. When would you use a different output location?

**Answer:** Framework projects often build source code into a folder such as `dist`, `build`, or `out`. For example, a Vite application often uses `dist`; then `output_location` would be `dist`, relative to the app location.

### Q11. What is the purpose of `actions/checkout`?

**Answer:** The GitHub Actions runner starts empty. Checkout retrieves the exact commit that triggered the workflow, so the deployment is reproducible and tied to a specific Git commit.

### Q12. What is a GitHub Actions runner?

**Answer:** It is the compute environment that executes workflow jobs. This workflow uses a GitHub-hosted Ubuntu runner. The runner is temporary, runs the workflow steps, and is then discarded.

### Q13. How would you prevent accidental production deployment?

**Answer:** Protect `main` and require pull requests before merging. Use a feature branch for each change, review the Azure preview environment, and merge only after review. For a team, I would also require approval and successful CI status checks.

### Q14. How would you implement a manually approved production release?

**Answer:** Use a GitHub Environment such as `production` with required reviewers, and attach the production deployment job to that environment. Alternatively, change the production workflow trigger to `workflow_dispatch`, which allows a maintainer to run the deployment manually from GitHub Actions. For this personal portfolio, PR review followed by merge to protected `main` is simpler and safer.

### Q15. What is the difference between a preview deployment and a production deployment?

**Answer:** A preview deployment is temporary and associated with a pull request; it exists for validation. Production deployment serves the public custom domain and is associated with the production branch. The content path can be the same, but the environment, URL, and release purpose differ.

### Q16. What happens when a pull request is closed?

**Answer:** The `close_pull_request_job` runs the Azure deployment action with `action: "close"`. This removes the temporary Azure preview environment. It does not delete the production site, the branch, or the source files.

### Q17. How would you troubleshoot a failed deployment?

**Answer:** Start in the GitHub Actions run linked from the Azure Static Web App deployment history. Identify whether checkout, build, path configuration, authentication, or Azure upload failed. Confirm that `app_location` and `output_location` match the repository structure, the GitHub secret exists with the expected name, and the static asset paths work using case-sensitive Linux rules. Fix the issue on a branch, validate the preview, then merge.

### Q18. What does a deployment token rotation involve?

**Answer:** Generate or reset the deployment token in Azure Static Web Apps, update the GitHub repository secret with the new value, run a controlled deployment, and then invalidate the old token. The token value should never be committed or shared in a chat, document, or screenshot.

### Q19. How would you add quality checks before deployment?

**Answer:** Add a separate validation job before deployment. For this static website I could run an HTML validator, link checker, simple JavaScript/CSS linting, and a browser-based smoke test. Make the deployment job depend on that validation job, then configure GitHub branch protection to require the checks to pass before merge.

### Q20. Why keep the workflow file in the repository?

**Answer:** It makes deployment logic version-controlled, reviewable, reproducible, and auditable. A change to the website and a change to how it is deployed can be reviewed together in a pull request.

### Q21. Is this workflow infrastructure as code?

**Answer:** It is pipeline as code, because it defines the delivery automation. Full infrastructure as code would additionally declare and manage the Azure Static Web App resource, custom domain, storage, SQL resources, networking, and identity through Bicep, Terraform, ARM, or Pulumi.

### Q22. What security risk applies to pull requests from forks?

**Answer:** GitHub does not pass repository secrets to workflows triggered from forks. That protects the deployment token from untrusted pull-request code. For a public repository, deployment workflows should be designed carefully so that untrusted changes cannot gain access to privileged credentials.

### Q23. Why is static hosting appropriate for AADData.com?

**Answer:** The site is currently a portfolio with static HTML, diagrams, and GitHub links. It has no server-side sessions, database writes, or private API. Azure Static Web Apps provides managed hosting, HTTPS, custom-domain support, preview environments, and GitHub-based delivery without operating a server.

### Q24. What would change if the dashboard becomes dynamic?

**Answer:** The static portfolio can remain in Azure Static Web Apps, but the dashboard needs a secure backend or API. I would use authenticated APIs, Azure Functions, Container Apps, or a managed dashboard service, keep database credentials server-side, and expose only controlled read endpoints to the browser.

## 7. Practical Interview Demonstration

When an interviewer asks for evidence, show these in order:

1. The repository's `website/index.html` to show the deployed source.
2. The workflow YAML to show `push` and `pull_request` triggers.
3. GitHub Actions history to show deployment runs.
4. A pull request showing the preview URL and the change diff.
5. Azure Static Web Apps Overview showing the production URL and deployment history.
6. The public site at `https://www.aaddata.com`.

## 8. Fast Revision Points

- Git is the source of truth; Azure deploys the commit that triggered the workflow.
- A GitHub Actions workflow is YAML-based automation stored under `.github/workflows`.
- `main` is the production release branch in this project.
- Pull requests provide review and preview environments before production deployment.
- `app_location` is source location; `output_location` is deployable output location.
- Secrets authorize workflow activity without appearing in source code.
- The Azure deployment token and `GITHUB_TOKEN` have different purposes.
- Branch protection is the control that prevents direct, unreviewed production changes.
- The current workflow is a strong deployment baseline; validation test jobs are the next CI improvement.

## 9. Official References

- [Azure Static Web Apps build configuration](https://learn.microsoft.com/en-us/azure/static-web-apps/build-configuration?tabs=github-actions)
- [Azure Static Web Apps pull-request previews](https://learn.microsoft.com/en-us/azure/static-web-apps/review-publish-pull-requests)
- [Azure Static Web Apps branch environments](https://learn.microsoft.com/en-us/azure/static-web-apps/branch-environments)
- [GitHub Actions secrets](https://docs.github.com/en/actions/reference/security/secrets)
- [GitHub branch protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
