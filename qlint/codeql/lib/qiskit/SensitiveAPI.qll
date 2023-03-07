
import semmle.python.ApiGraphs

class IBMCloudTokenSink extends DataFlow::Node {
    IBMCloudTokenSink() {
        this = API::moduleImport("qiskit")
            .getMember("IBMQ").getMember("enable_account").getACall()
            .getParameter(0, "token").asSink()
        or
        this = API::moduleImport("qiskit")
            .getMember("IBMQ").getMember("save_account").getACall()
            .getParameter(0, "token").asSink()
        or
        this = API::moduleImport("qiskit_ibm_experiment")
            .getMember("IBMExperimentService").getMember("save_account").getACall()
            .getParameter(1, "token").asSink()
    }
}