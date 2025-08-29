// pageextension 80935 Pgext_ProdOrderComponents extends "Prod. Order Components"
// {
//     layout
//     {
//         // Add changes to page layout here
//     }

//     actions
//     {
//         // Add changes to page actions here
//     }

//     trigger OnOpenPage()
//     var
//         myInt: Integer;
//     begin
//         Activate_lFnc;

//     end;

//     trigger OnAfterGetRecord()
//     begin
//         // Activate_lFnc;
//     end;

//     trigger OnAfterGetCurrRecord()
//     begin
//         // Activate_lFnc;
//     end;

//     trigger OnNewRecord(BelowxRec: Boolean)
//     begin
//         // Activate_lFnc;
//     end;

//     Local procedure Activate_lFnc()
//     var
//         ProductionOrder_lRec: Record "Production Order";
//     begin
//         Message('%1', rec."Prod. Order No.");
//         if ProductionOrder_lRec.Get(Rec.Status, rec."Prod. Order No.") then begin
//             if ProductionOrder_lRec."Order Status" in [ProductionOrder_lRec."Order Status"::Released, ProductionOrder_lRec."Order Status"::"Pending Approval", ProductionOrder_lRec."Order Status"::Closed] then
//                 CurrPage.Editable := false;
//         end;
//     end;

//     var
//         myInt: Integer;
// }