'use strict';

const fs = require('fs');
const exec = require('child_process').exec;
const crypto = require('crypto');
const changelogPath = './.gitlab-ci/changelog.json';

if (undefined === process.env.ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION) {
    console.error('You need to set ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION env variable, for e.g.: ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION=2')
    process.exit();
}

let composerLock = JSON.parse(fs.readFileSync('composer.lock'));
let composer = JSON.parse(fs.readFileSync('composer.json'));
let samBundlesLockPath = './.gitlab-ci/sam-bundles.lock';
if (!fs.existsSync(samBundlesLockPath)) {
    fs.writeFileSync(samBundlesLockPath, JSON.stringify({
        packages: {}
    }, null, 4));
}
let samBundlesLock = JSON.parse(fs.readFileSync(samBundlesLockPath));
if (!fs.existsSync(changelogPath)) {
    fs.writeFileSync(changelogPath, '{}');
}

let args = process.argv;

var checkPackage = function (pkg) {
    return new Promise(function (resolve, reject) {
        if (pkg.name.startsWith('sam/')) {
            exec('git remote -v', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                if (args.length === 2 || args[2] === 'tags') {
                    if (stdout.toString().includes('my-sam/core/')) {
                        // Load last tags
                        exec('git fetch --tags', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                            // Load last tag
                            exec('git describe --tags $(git rev-parse ' + process.env.ENVIRONMENT_SAM_VENDOR_MAJOR_VERSION + '.x) --abbrev=0', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                                if (!err && !stderr) {
                                    var versionNumber = stdout.toString().trim();
                                    if (versionNumber) {
                                        // Get commit id from tag name
                                        exec('git rev-list -n 1 ' + versionNumber, {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                                            if (!err && !stderr) {
                                                loadChangelog(pkg, versionNumber);

                                                let lastCommit = stdout.toString().trim();
                                                let oldCommit = pkg.source.reference;
                                                pkg.source.reference = lastCommit;
                                                pkg.time = new Date().toISOString();
                                                pkg.version = versionNumber;
                                                pkg.dist.reference = lastCommit;
                                                pkg.dist.url = pkg.dist.url.replace(oldCommit, lastCommit);
                                                // Update version in composer.json
                                                composer.require[pkg.name] = versionNumber;
                                                console.log(pkg.name + ' updated.');
                                                resolve();
                                            } else {
                                                console.error('Cant\'t load last commit for: ' + pkg.name);
                                                reject(err);
                                            }
                                        });
                                    } else {
                                        console.error('Cant\'t get tag version: ' + pkg.name);
                                        reject(err);
                                    }
                                } else {
                                    console.error('Cant\'t load last tag for: ' + pkg.name);
                                    reject(err);
                                }
                            });
                        });
                    } else {
                        console.error('GIT doesn\'t point to the right repository for: ' + pkg.name);
                        reject(err);
                    }
                } else {
                    exec('git rev-parse --short HEAD', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                        if (!err && !stderr) {
                            var shortCommitHash = stdout.toString().trim();
                            exec('git rev-parse HEAD', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                                if (!err && !stderr) {
                                    var commitHash = stdout.toString().trim();
                                    exec('git rev-parse --abbrev-ref HEAD', {cwd: './vendor/' + pkg.name}, function (err, stdout, stderr) {
                                        if (!err && !stderr) {
                                            var branchName = stdout.toString().trim();
                                            var process = true;
                                            if (branchName === 'HEAD') {
                                                process = false;
                                            }

                                            if (process) {
                                                var versionNumber = 'dev-master#' + commitHash;
                                                let oldCommit = pkg.source.reference;

                                                pkg.source.reference = commitHash;
                                                pkg.time = new Date().toISOString();
                                                pkg.version = 'dev-master';
                                                pkg.dist.reference = commitHash;
                                                pkg.dist.url = pkg.dist.url.replace(oldCommit, commitHash);
                                                // Update version in composer.json
                                                composer.require[pkg.name] = versionNumber;
                                                composerLock['stability-flags'][pkg.name] = 20;
                                            } else {
                                                delete composerLock['stability-flags'][pkg.name];
                                            }
                                            resolve();
                                        } else {
                                            console.error('Cant\'t get branch name for: ' + pkg.name);
                                            reject(err);
                                        }
                                    });
                                } else {
                                    console.error('Cant\'t get short commit for: ' + pkg.name);
                                    reject(err);
                                }
                            });
                        } else {
                            console.error('Cant\'t get short commit for: ' + pkg.name);
                            reject(err);
                        }
                    });
                }
            });
        } else {
            resolve();
        }
    });
};

var loadChangelog = function (pkg, newVersion) {
    if (pkg.name in samBundlesLock.packages && newVersion !== samBundlesLock.packages[pkg.name].version) {
        let content = fs.readFileSync('./vendor/' + pkg.name + '/CHANGELOG.md');
        let contentOutput = JSON.parse(fs.readFileSync(changelogPath));
        if (!contentOutput) {
            contentOutput = {};
        }
        let lines = content.toString().split('\n');
        let copy = false;
        let key = 'fixed';
        lines.forEach(function (line) {
            if (line.includes("## [Unreleased]")) {
                copy = true;
            } else if (line.includes("## [" + samBundlesLock.packages[pkg.name].version + "]")) {
                copy = false;
            } else if (copy) {
                if (line.startsWith('###')) {
                    key = line.replace('### ', '').trim().toLowerCase();
                } else if (line && line.trim() && line.length > 0 && !line.startsWith('##')) {
                    if (!contentOutput[key]) {
                        contentOutput[key] = {};
                    }

                    if (!contentOutput[key].hasOwnProperty(line)) {
                        contentOutput[key][line] = line;
                    }
                }
            }
        });

        fs.writeFileSync(changelogPath, JSON.stringify(contentOutput, null, 4));
    } else {
        samBundlesLock.packages[pkg.name] = {
            'name': pkg.name,
            'version': newVersion
        };
    }

    samBundlesLock.packages[pkg.name].version = newVersion;
};

console.log('Starting to read composer.lock...\r\n');

let actions = composerLock.packages.map(checkPackage);

Promise.all(actions).then(function () {
    let content = JSON.parse(JSON.stringify(composer));
    let relevantKeys = [
        'name',
        'version',
        'require',
        'require-dev',
        'conflict',
        'replace',
        'provide',
        'minimum-stability',
        'prefer-stable',
        'repositories',
        'extra',
    ];
    let relevantContent = [];
    for (const [key, value] of Object.entries(relevantKeys.filter(value => Object.keys(content).includes(value)))) {
        relevantContent[value] = content[value];
    }

    if (content['config'] && content['config']['platform']) {
        if (!relevantContent['config']) {
            relevantContent['config'] = { 'platform': {}};
        }
        relevantContent['config']['platform'] = content['config']['platform'];
    }

    relevantContent = ksort(relevantContent);

    let newContentHash = crypto.createHash('md5').update(JSON.stringify(relevantContent).replace(/\//g, "\\\/")).digest("hex");
    composerLock['content-hash'] = newContentHash;

    // Write back composer.lock
    let data = JSON.stringify(composerLock, null, 4);
    fs.writeFileSync('composer.lock', data);
    // Write back composer.json
    data = JSON.stringify(composer, null, 4);
    fs.writeFileSync('composer.json', data);
    // Write back sam-bundles.lock
    data = JSON.stringify(samBundlesLock, null, 4);
    fs.writeFileSync('./.gitlab-ci/sam-bundles.lock', data);
    console.log('\\o/ \\o/ \\o/');
    console.log('\r\ncomposer.lock and composer.json updated\r\n');
}, function (err) {
    console.error(err);
});

function ksort (obj) {
  var keys = Object.keys(obj).sort()
    , sortedObj = {};

  for (var i in keys) {
    sortedObj[keys[i]] = obj[keys[i]];
  }

  return sortedObj;
}

