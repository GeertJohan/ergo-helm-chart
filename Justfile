_default:
    @just --list

# Package and push chart to GitHub Container Registry
package-and-push:
    #!/usr/bin/env bash
    set -euo pipefail

    # Check if working directory is clean
    if [[ -n $(git status --porcelain) ]]; then
        echo "Error: Git working directory is not clean"
        exit 1
    fi

    # Get current commit
    COMMIT=$(git rev-parse HEAD)

    # Get tag pointing to current commit
    TAG=$(git tag --points-at HEAD | head -n1)

    if [[ -z "$TAG" ]]; then
        echo "Error: No git tag found on current commit"
        exit 1
    fi

    echo "Packaging chart version $TAG..."
    helm package ergo

    echo "Pushing to ghcr.io/geertjohan..."
    helm push ergo-${TAG}.tgz oci://ghcr.io/geertjohan

    echo "Successfully published version $TAG"
