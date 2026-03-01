import { 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  query, 
  limit, 
  startAfter,
  updateDoc,
  QueryConstraint,
  DocumentData,
  Timestamp,
  collectionGroup
} from "firebase/firestore";
import { db } from "@lib/firebase";

export interface PaginationParams {
  pageIndex: number;
  pageSize: number;
  lastDoc?: DocumentData;
}

export interface FirestoreResponse<T> {
  data: T[];
  total: number;
  hasMore: boolean;
  lastDoc?: DocumentData;
}

// Generic Firestore service
export class FirestoreService {
  // Convert Firestore data to plain objects
  private static convertFirestoreData(data: DocumentData): any {
    const converted: any = {};
    for (const [key, value] of Object.entries(data)) {
      if (value && typeof value === 'object' && 'toDate' in value) {
        // Convert Firestore Timestamp to ISO string
        converted[key] = value.toDate().toISOString();
      } else if (value && typeof value === 'object' && 'seconds' in value) {
        // Handle Timestamp-like objects
        converted[key] = new Date(value.seconds * 1000).toISOString();
      } else {
        converted[key] = value;
      }
    }
    return converted;
  }

  // Get paginated collection
  static async getPaginatedCollection<T>(
    collectionName: string,
    pagination: PaginationParams,
    filters?: QueryConstraint[]
  ): Promise<FirestoreResponse<T>> {
    const collectionRef = collection(db, collectionName);
    const constraints: QueryConstraint[] = filters || [];
    
    // Add pagination
    constraints.push(limit(pagination.pageSize));
    if (pagination.lastDoc) {
      constraints.push(startAfter(pagination.lastDoc));
    }

    const q = query(collectionRef, ...constraints);
    const snapshot = await getDocs(q);
    
    const data = snapshot.docs.map(doc => ({
      id: doc.id,
      ...this.convertFirestoreData(doc.data()),
    })) as T[];

    return {
      data,
      total: snapshot.size,
      hasMore: snapshot.docs.length === pagination.pageSize,
      lastDoc: snapshot.docs[snapshot.docs.length - 1],
    };
  }

  // Get all documents from a collection group (for subcollections)
  static async getAllFromCollectionGroup<T>(
    collectionName: string,
    filters?: QueryConstraint[]
  ): Promise<T[]> {
    const collectionRef = collectionGroup(db, collectionName);
    const constraints: QueryConstraint[] = filters || [];
    const q = query(collectionRef, ...constraints);
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...this.convertFirestoreData(doc.data()),
    })) as T[];
  }

  // Get all documents (for smaller collections)
  static async getAllDocuments<T>(
    collectionName: string,
    filters?: QueryConstraint[]
  ): Promise<T[]> {
    const collectionRef = collection(db, collectionName);
    const constraints: QueryConstraint[] = filters || [];
    const q = query(collectionRef, ...constraints);
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...this.convertFirestoreData(doc.data()),
    })) as T[];
  }

  // Get single document
  static async getDocument<T>(
    collectionName: string,
    docId: string
  ): Promise<T | null> {
    const docRef = doc(db, collectionName, docId);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return {
        id: docSnap.id,
        ...this.convertFirestoreData(docSnap.data()),
      } as T;
    }
    return null;
  }

  // Update document
  static async updateDocument(
    collectionName: string,
    docId: string,
    data: Partial<DocumentData>
  ): Promise<void> {
    const docRef = doc(db, collectionName, docId);
    await updateDoc(docRef, data);
  }

  // Convert Firestore Timestamp to Date string
  static timestampToDate(timestamp: Timestamp | any): string {
    if (timestamp?.toDate) {
      return timestamp.toDate().toISOString().split('T')[0];
    }
    return new Date().toISOString().split('T')[0];
  }
}
