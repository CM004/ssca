//
//  PaywallView.swift
//  SamvaadFlow
//
//  Sheet shown when tapping a locked domain. One-time $2 unlock for all.
//

import SwiftUI

struct PaywallView: View {

    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Spacer()

                // Icon
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Unlock All Domains")
                    .font(.title.weight(.bold))

                Text("Get full access to Healthcare, Legal, Finance, and Support prompt engineering modules.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Domain list
                VStack(alignment: .leading, spacing: 10) {
                    domainRow(icon: "cross.case.fill", name: "Healthcare", desc: "Medical triage prompts")
                    domainRow(icon: "scalemass.fill", name: "Legal", desc: "Contract review prompts")
                    domainRow(icon: "indianrupeesign.circle.fill", name: "Finance", desc: "Investment planning prompts")
                    domainRow(icon: "headphones.circle.fill", name: "Support", desc: "Tech support prompts")
                }
                .padding(.horizontal, 24)

                Spacer()

                // Purchase button
                Button {
                    Task { await store.purchase() }
                } label: {
                    if let product = store.product {
                        Text("Unlock All — \(product.displayPrice)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Unlock All — $2.00")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.green)
                .padding(.horizontal, 24)

                // Restore
                Button("Restore Purchase") {
                    Task { await store.restore() }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if let error = store.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer().frame(height: 16)
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: store.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private func domainRow(icon: String, name: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.weight(.semibold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
