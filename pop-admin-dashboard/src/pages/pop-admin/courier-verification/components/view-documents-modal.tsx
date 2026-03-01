import { Button } from "@components/ui/button";
import { Badge } from "@components/ui/badge";
import { useModal } from "@saimin/react-modal-manager";
import { X, Download, CheckCircle, XCircle } from "lucide-react";

type ViewDocumentsModalProps = {
  verification: {
    id: string;
    courierName: string;
    email: string;
    phone: string;
    vehicleType: string;
    vehicleName: string;
    plateNumber: string;
    submittedAt: string;
    documents: string;
    status: string;
  };
};

export function ViewCourierDocumentsModal({ verification }: ViewDocumentsModalProps) {
  const { closeAll } = useModal();

  // Mock document URLs - will be replaced with real URLs from Firebase
  const documents = {
    idFront: "https://via.placeholder.com/600x400?text=ID+Front",
    idBack: "https://via.placeholder.com/600x400?text=ID+Back",
    faceScan: "https://via.placeholder.com/600x400?text=Face+Scan",
  };

  return (
    <div className="w-[800px] max-h-[90vh] overflow-y-auto rounded-lg bg-background p-6">
      <div className="flex items-start justify-between mb-6">
        <div>
          <h2 className="text-2xl font-bold">{verification.courierName}</h2>
          <div className="flex gap-4 mt-2 text-sm">
            <span>{verification.email}</span>
            <span>{verification.phone}</span>
          </div>
          <div className="mt-3 p-3 bg-muted rounded-lg">
            <div className="grid grid-cols-3 gap-4 text-sm">
              <div>
                <p className="text-muted-foreground">Vehicle Type</p>
                <p className="font-medium">{verification.vehicleType}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Vehicle Model</p>
                <p className="font-medium">{verification.vehicleName}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Plate Number</p>
                <p className="font-medium">{verification.plateNumber}</p>
              </div>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge>{verification.status}</Badge>
          <Button variant="ghost" size="icon" onClick={closeAll}>
            <X className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="space-y-6">
        {/* ID Front */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <h3 className="font-semibold">ID Document (Front)</h3>
            <Button variant="outline" size="sm">
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
          </div>
          <div className="border rounded-lg overflow-hidden">
            <img 
              src={documents.idFront} 
              alt="ID Front" 
              className="w-full h-auto"
            />
          </div>
        </div>

        {/* ID Back */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <h3 className="font-semibold">ID Document (Back)</h3>
            <Button variant="outline" size="sm">
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
          </div>
          <div className="border rounded-lg overflow-hidden">
            <img 
              src={documents.idBack} 
              alt="ID Back" 
              className="w-full h-auto"
            />
          </div>
        </div>

        {/* Face Scan */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <h3 className="font-semibold">Face Scan</h3>
            <Button variant="outline" size="sm">
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
          </div>
          <div className="border rounded-lg overflow-hidden">
            <img 
              src={documents.faceScan} 
              alt="Face Scan" 
              className="w-full h-auto"
            />
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      {verification.status === "pending" && (
        <div className="flex gap-4 mt-6 pt-6 border-t">
          <Button 
            variant="default" 
            className="flex-1"
            onClick={() => {
              // TODO: Implement approve logic
              console.log("Approve courier:", verification.id);
              closeAll();
            }}
          >
            <CheckCircle className="h-4 w-4 mr-2" />
            Approve Courier
          </Button>
          <Button 
            variant="destructive" 
            className="flex-1"
            onClick={() => {
              // TODO: Implement reject logic
              console.log("Reject courier:", verification.id);
              closeAll();
            }}
          >
            <XCircle className="h-4 w-4 mr-2" />
            Reject Courier
          </Button>
        </div>
      )}
    </div>
  );
}
