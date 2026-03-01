import { Button } from "@components/ui/button";
import { Badge } from "@components/ui/badge";
import { useModal } from "@saimin/react-modal-manager";
import { X, Download, CheckCircle, XCircle } from "lucide-react";

type ViewDocumentsModalProps = {
  verification: {
    id: string;
    storeName: string;
    ownerName: string;
    email: string;
    phone: string;
    submittedAt: string;
    documents: string;
    status: string;
  };
};

export function ViewDocumentsModal({ verification }: ViewDocumentsModalProps) {
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
          <h2 className="text-2xl font-bold">{verification.storeName}</h2>
          <p className="text-muted-foreground">{verification.ownerName}</p>
          <div className="flex gap-4 mt-2 text-sm">
            <span>{verification.email}</span>
            <span>{verification.phone}</span>
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
              console.log("Approve verification:", verification.id);
              closeAll();
            }}
          >
            <CheckCircle className="h-4 w-4 mr-2" />
            Approve Verification
          </Button>
          <Button 
            variant="destructive" 
            className="flex-1"
            onClick={() => {
              // TODO: Implement reject logic
              console.log("Reject verification:", verification.id);
              closeAll();
            }}
          >
            <XCircle className="h-4 w-4 mr-2" />
            Reject Verification
          </Button>
        </div>
      )}
    </div>
  );
}
