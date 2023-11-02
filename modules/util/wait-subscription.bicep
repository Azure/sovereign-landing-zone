// ----------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
//
// THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
// EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
// ----------------------------------------------------------------------------------

targetScope = 'subscription'

@description('Loop Counter.')
@minValue(1)
param parLoopCounter int

@description('Prefix used for loop.')
@minLength(2)
@maxLength(50)
param parWaitNamePrefix string

@batchSize(1)
module modWait 'wait-on-arm-subscription.bicep' = [for i in range(1, parLoopCounter): {
  scope: subscription()
  name: '${parWaitNamePrefix}-${i}'
  params: {
    parInput: 'waitOnArm-${i}'
  }
}]
