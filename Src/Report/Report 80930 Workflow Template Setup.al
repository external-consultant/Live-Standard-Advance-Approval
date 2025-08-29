// report 80930 "Workflow Template Setup"
// {
//     Caption = 'Workflow Template Setup';
//     ApplicationArea = All;
//     UsageCategory = ReportsAndAnalysis;
//     ProcessingOnly = true;




//     requestpage
//     {
//         layout
//         {
//             area(Content)
//             {
//                 group(GroupName)
//                 {
//                     field("Workflow Template"; "Workflow Template")
//                     {
//                         ApplicationArea = All;
//                     }
//                 }
//             }
//         }

//         actions
//         {
//             area(processing)
//             {
//                 action(ActionName)
//                 {
//                     ApplicationArea = All;

//                 }
//             }
//         }
//     }


//     trigger OnPreReport()
//     var
//         CustomWorkflowSetup_gCdu: Codeunit "Workflow Setup Ext";
//         WorkflowSetup_gCdu: Codeunit "Workflow Setup";
//         ApprovalEntry_gRec: Record "Approval Entry";
//         Workflow_gRec: Record Workflow;
//     begin
//         case "Workflow Template" of
//             "Workflow Template"::Delete:
//                 begin
//                     Workflow_gRec.Reset();
//                     if Workflow_gRec.FindSet() then
//                         repeat
//                             Workflow_gRec.Get('MS-PRODUCTIONORDERPW');
//                             Workflow_gRec.Validate(Template, false);
//                             Workflow_gRec.Enabled := false;
//                             Workflow_gRec.Modify(true);
//                             Workflow_gRec.Delete(true);
//                         until Workflow_gRec.Next() = 0;
//                     Message('Workflow Template Deleted');
//                 end;
//             "Workflow Template"::Create:
//                 begin
//                     CustomWorkflowSetup_gCdu.InsertProductionOrderApprovalWorkflowTemplate();//Step-1
//                     WorkflowSetup_gCdu.InsertTableRelation(DATABASE::"Production Order", 0, DATABASE::"Approval Entry", ApprovalEntry_gRec.FieldNo("Record ID to Approve"));//Step-2
//                     Message('Workflow Template Created');

//                 end;
//         end;
//     end;

//     var
//         "Workflow Template": Option ,Create,Delete;
// }
