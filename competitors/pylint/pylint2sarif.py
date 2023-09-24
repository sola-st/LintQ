
"""
Convert the output of Pylint to SARIF.

CREDITS: https://github.com/GrammaTech/pylint-sarif/blob/master/pylint2sarif.py

"""
import sys
import os
import argparse
import subprocess
import re
import platform
import json
import python_jsonschema_objects as pjs
import uuid
import tempfile
import pathlib


def check_prerequisites():
    """Check all requirements for successful execution and exit on failure"""
    if sys.platform == 'cygwin':
        sys.stderr.write('pylint2sarif: running this script from a cygwin python is not supported.\n' +
                         'Use a standard windows Python install instead.\n')
        sys.exit(1)


def log(message):
    """Log a message to stdout with a helpful prefix"""
    sys.stdout.write("Pylint2sarif: {}\n".format(message))
    sys.stdout.flush()


# This is used to match lines that are output by "pylint --list-msgs"
MSGRE = re.compile(r'^:([^\(]*) \(([^\)]+)\):( \*([^\*]+)\*)?$')


def remove_caret_part(message):
    """Pylint messages are sometimes of the following form:

    Exactly one space required after comma
    os.path.join(os.environ['x'],"four","five")
                                ^

    This looks terrible unless it is properly formatted with a fixed-width
    font. Ultimately, these will be translated into rich text and formatted
    in that way, but the regular non-rich-text property of a message object
    will have the line with the caret and everything associated with it stripped
    out. The coordinates of where the caret points to are also present,
    so this is no big loss. The regexp CARET_RE matches everything on
    the line with the caret on it to the end.

    >>> remove_caret_part('one')
    'one'
    >>> remove_caret_part('two\\n  code\\n    ^')
    'two'
    >>> remove_caret_part('three\\n   more code\\n    |   ^')
    'three'
    >>> remove_caret_part('four\\n  !@#$%^&*() code\\n    |   ^')
    'four'
    """
    match = CARET_RE.match(message)
    if match is None:
        return message
    return match.group(1)

CARET_RE = re.compile(r"(.*)\n.*\n[ \|]*\^.*$", re.DOTALL)

DRIVE_RE = re.compile(r"^[a-zA-Z]:")

def path2uri(path):
    """Create a Sarif URI from a pathname

    This is slightly tricky because the path can be relative or
    absolute. If it is a Linux absolute it is like '/a/b.c',
    but a Windows absolute is 'C:\a\b.c'. Just prefixing
    'file:///' isn't good enough because that's one too many slashes
    for Linux. So, only prefix three slashes if it starts with a Windows
    drive specifier.
    """
    path = path.replace('\\', '/')
    if DRIVE_RE.match(path):
        path = '/' + path
    return 'file://' + path

PYLINT_HELP = r"""pylint2sarif: failed to invoke pylint with command line {}.
Please make sure that pylint is installed and in your PATH.
On Windows this is likely in a location such as 'C:\Python37\Scripts'.
Please see https://www.pylint.org for details on how to install
and use pylint.
Exception:
{}
"""

PYLINT_ERRCODE = """pylint2sarif: pylint returned non-zero exit code {} with command line {}.
"""

PYLINT_RETURNCODE_DESCRIPTION = """pylint2sarif: pylint returned an exit code of {}, indicating:
             '{}'
"""

PYLINT_FAILURE = """Pylint encountered a fatal error; its output is shown below.\n"""


def mk_id(identifier):
    """Make an id from a string such as 'C0326'."""
    return identifier


def mk_level(ptype):
    """Convert a Pylint warning "type" to a Sarif level"""
    ldict = {'error': 'error',
             'warning': 'warning',
             'refactor': 'note',
             'convention': 'note',
             'usage': 'note'}
    return ldict.get(ptype, 'note')


class Pylint2Sarif(object):
    """Top-level class for converting Pylint output to SARIF"""
    def __init__(self, args):
        self.args = args
        random_id = uuid.uuid4()
        path_current_file = os.path.dirname(os.path.abspath(__file__))
        # crete a tmp folder
        pathlib.Path(
            os.path.join(path_current_file, 'tmp')).mkdir(
                parents=True, exist_ok=True)
        # create a gitignore in it
        with open(os.path.join(path_current_file, 'tmp', '.gitignore'), 'w') as f:
            f.write('*')
        filename = f'pylintout_{random_id}.txt'
        self.tmpfile = os.path.join(path_current_file, 'tmp', filename)

        builder = pjs.ObjectBuilder(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sarif-schema.json'))
        self.sarif = builder.build_classes()

    def mk_sarif_result(self, pylint_warning):
        """Create a Sarif Result object from a Pylint warning"""
        message_text = remove_caret_part(pylint_warning['message'])
        if message_text[-1] != '.':
            message_text += '.'
        floc = self.sarif.Artifactlocation(uri=path2uri(os.path.abspath(pylint_warning['path'])))

        loc = self.sarif.Location(
            physicalLocation=self.sarif.Physicallocation(
                artifactLocation=floc,
                    region=self.sarif.Region(
                        startLine=pylint_warning['line'],
                        startColumn=pylint_warning['column']+1)))
        result = self.sarif.Result(
            message=self.sarif.Messageclass(text=str(message_text)),
            ruleId=mk_id(pylint_warning['message-id']),
            locations=[loc])

        return result

    def mk_configuration(self, rule_id):
        """Make a configuration object for a rule

        Return a ReportingConfiguration object
        In Pylint, the first character of the rule ID indicates its level.
        """
        ldict = {'C': 'note',    # Convention
                 'E': 'error',   # Error
                 'R': 'note',    # Refactor
                 'W': 'warning', # Warning
                 'I': 'note',    # Informational
                 'F': 'error'    # Failure
            }
        return self.sarif.Reportingconfiguration(level=ldict.get(rule_id[0], 'note'))

    def mk_codesonar_rule_property_bag(self, rule_id):
        """Create a special property bag for the use of CodeSonar

        This will contain the mapping to significance as follows:
            'reliability': cs.warning_significance.RELIABILITY,
            'diagnostic': cs.warning_significance.DIAGNOSTIC,
            'from_manifest': cs.warning_significance.FROM_MANIFEST,
            'redundancy': cs.warning_significance.REDUNDANCY,
            'security': cs.warning_significance.SECURITY,
            'style': cs.warning_significance.STYLE,
            'unspecified': cs.warning_significance.UNSPECIFIED
        The first letter of the rule_id is used to make the determination.
        """
        sdict = {'C': 'style',       # Convention
                 'E': 'reliability', # Error
                 'R': 'style',       # Refactor
                 'W': 'reliability', # Warning
                 'I': 'style',       # Informational
                 'F': 'diagnostic'   # Failure
            }
        significance = sdict.get(rule_id[0])
        if significance is None:
            return {}
        return { "CodeSonar": { "significance": significance } }

    def flush_rule(self, rule_id, rule_name, full_description):
        """Flush all information about a pending rule, and return it"""

        def clean_sentence(msg):
            """Bring the sentences into line with what is expected by Sarif: no leading
            spaces and a terminating period.
            """
            if msg is None:
                return None
            import string
            return msg.lstrip().rstrip(string.whitespace+'.') + '.'
        rule = self.sarif.Reportingdescriptor(
            id=rule_id,
            name=rule_name,
            defaultConfiguration=self.mk_configuration(rule_id),
            fullDescription=self.sarif.Multiformatmessagestring(text=clean_sentence(full_description)),
            properties=self.mk_codesonar_rule_property_bag(rule_id),
            helpUri="http://pylint-messages.wikidot.com/messages:{}".format(rule_id)
        )
        return rule

    def create_rules(self):
        """Create the array of reportingDescriptor objects consisting of the rules

        Do this by invoking pylint in a mode that lists the rules, then converting
        each one to a reportingDescriptor object.
        """
        cmdline = ['pylint', '--list-msgs']
        rule_id = None
        rule_name = None
        message_string = None
        full_description = None
        rules = []
        try:
            log("invoking {}".format(cmdline))
            proc = subprocess.Popen(cmdline, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except Exception as e:
            sys.stderr.write(PYLINT_HELP.format(cmdline, e))
            sys.exit(1)
        # The output from this command is stored in memory, but it should have no trouble
        # fitting. With defaults, it is only about 60kb.
        (out, err) = proc.communicate()
        sys.stderr.write(err.decode('utf-8'))
        # Invoking pylint in this manner should yield exit code zero.
        if proc.returncode != 0:
            sys.stderr.write(PYLINT_ERRCODE.format(proc.returncode, cmdline))
            sys.exit(1)
        for line in out.splitlines():
            sline = line.decode('utf-8').rstrip()
            m = MSGRE.match(sline)
            if m is None:
                full_description = str(full_description) + ' ' + sline
            else:
                if rule_id is not None:
                    rules.append(self.flush_rule(rule_id, rule_name, full_description))
                rule_name = m.group(1)
                rule_id = mk_id(m.group(2))
                message_string = m.group(4)
                full_description = ''
        # TODO: The message_string should be converted into a rule.messageStrings object.
        rules.append(self.flush_rule(rule_id, rule_name, full_description))
        return rules

    def run_pylint(self):
        """Invoke pylint to output json, then convert that to SARIF"""
        rules = self.create_rules()
        retcode = 0
        with open(self.tmpfile, 'w') as fp:
            cmdline = ["pylint",
                       "-f",
                       "json",
                       "-r",
                       "n"]
            cmdline += self.args.inputs
            log("invoking {}".format(cmdline))
            retcode = subprocess.call(cmdline, stdout=fp)
            if retcode == 0:
                return_description = 'Successful completion. No messages.'
            else:
                return_description = ''
                if retcode & 1:
                    return_description = 'Fatal message issued. '
                if retcode & 2:
                    return_description += 'Error message issued. '
                if retcode & 4:
                    return_description += 'Warning message issued. '
                if retcode & 8:
                    return_description += 'Refactor message issued. '
                if retcode & 16:
                    return_description += 'Convention message issued. '
                if retcode & 32:
                    return_description += 'Usage error.'
            sys.stdout.write(PYLINT_RETURNCODE_DESCRIPTION.format(retcode, return_description))
            if retcode & 1:
                sys.stderr.write(PYLINT_FAILURE)
                with open(self.tmpfile, 'r') as fp:
                    for line in fp:
                        sys.stderr.write(line)
                sys.exit(1)

        with open(self.tmpfile, 'r') as fp:
            content = fp.read()
            warnings = json.loads(content)

        results = [] # this is a list of self.sarif.result
        for pylint_warning in warnings:
            result = self.mk_sarif_result(pylint_warning)
            results.append(result)

        driver = self.sarif.Toolcomponentclass(name="pylint", rules=rules)
        tool = self.sarif.Toolclass()
        tool.driver = driver
        invocation = self.sarif.Invocation(
            commandLine=' '.join(cmdline),
            arguments=cmdline[1:],
            machine=platform.node(),
            workingDirectory=self.sarif.Artifactlocation(uri=path2uri(os.getcwd())),
            executionSuccessful=True,
            exitCode=retcode,
            exitCodeDescription=return_description)
        run = self.sarif.Run(tool=tool, invocations=[invocation], results=results)

        # I can't use the constructor directly because it contains characters
        # that are invalid in Python.
        ctor = getattr(self.sarif, "StaticAnalysisResultsFormatSarifVersion210JsonSchema")
        sarif_log = ctor(version="2.1.0", runs=[run])

        with open(self.args.sarif_output, 'w') as out_file:
            out_file.write(sarif_log.serialize(indent=4))


def main():
    """Entry point to this program"""
    check_prerequisites()
    parser = argparse.ArgumentParser(description='Run pylint and convert the output to SARIF')
    parser.add_argument('--sarif-output', dest='sarif_output',
                        default='pylint.sarif',
                        help='The name of the SARIF file')
    parser.add_argument('--doctest', action='store_true', help='Run doctest on this Python file')
    parser.add_argument('inputs', nargs='*',
                        help='The names of the Python files')

    args = parser.parse_args()
    if args.doctest:
        import doctest
        doctest.testmod()
        return
    if not args.inputs:
        sys.stderr.write("Error: no inputs were specified\n")
        parser.print_help(sys.stderr)
        return
    p2s = Pylint2Sarif(args)
    p2s.run_pylint()


if __name__ == '__main__':
    main()