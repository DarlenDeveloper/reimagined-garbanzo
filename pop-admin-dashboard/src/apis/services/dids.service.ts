import { orderBy, where } from "firebase/firestore";
import { FirestoreService } from "./firestore.service";

export interface DID {
  id: string;
  phoneNumber: string;
  assigned: boolean;
  assignedTo?: string;
  assignedStoreName?: string;
  status: 'active' | 'inactive';
  createdAt: string;
}

export const DIDsService = {
  async getAllDIDs() {
    const dids = await FirestoreService.getAllDocuments<any>(
      'dids',
      [orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults
    return dids.map(did => ({
      ...did,
      phoneNumber: did.phoneNumber || did.number || did.phone || 'N/A',
      assigned: did.assigned || did.isAssigned || false,
      assignedTo: did.assignedTo || did.storeId || undefined,
      assignedStoreName: did.assignedStoreName || did.storeName || undefined,
      status: did.status || (did.assigned ? 'active' : 'inactive'),
    }));
  },

  async getAvailableDIDs() {
    const dids = await FirestoreService.getAllDocuments<any>(
      'dids',
      [where('assigned', '==', false), orderBy('createdAt', 'desc')]
    );
    
    // Map and provide defaults
    return dids.map(did => ({
      ...did,
      phoneNumber: did.phoneNumber || did.number || did.phone || 'N/A',
      assigned: did.assigned || did.isAssigned || false,
      status: did.status || 'inactive',
    }));
  },

  async assignDID(didId: string, storeId: string, storeName: string) {
    return FirestoreService.updateDocument('dids', didId, {
      assigned: true,
      assignedTo: storeId,
      assignedStoreName: storeName,
    });
  },

  async unassignDID(didId: string) {
    return FirestoreService.updateDocument('dids', didId, {
      assigned: false,
      assignedTo: null,
      assignedStoreName: null,
    });
  },
};
